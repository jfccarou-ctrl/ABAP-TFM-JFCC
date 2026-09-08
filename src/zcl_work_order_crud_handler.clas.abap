CLASS zcl_work_order_crud_handler DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

  TYPES tt_work_orders TYPE STANDARD TABLE OF ztfm_work_order
  WITH EMPTY KEY.

  METHODS create_work_order
      IMPORTING
        iv_work_order_id TYPE zde_work_order_id
        iv_customer_id   TYPE zde_customer_id
        iv_technician_id TYPE zde_technician_id
        iv_priority      TYPE zde_tfm_priority
        iv_description   TYPE zde_wo_description
      RETURNING
        VALUE(rv_created) TYPE abap_bool.

    METHODS read_work_order
      IMPORTING
        iv_work_order_id TYPE zde_work_order_id
      RETURNING
        VALUE(rs_work_order) TYPE ztfm_work_order.

    METHODS read_work_orders
    IMPORTING
    iv_creation_date_from TYPE ztfm_work_order-creation_date OPTIONAL
    iv_creation_date_to   TYPE ztfm_work_order-creation_date OPTIONAL
    iv_status             TYPE zde_tfm_status OPTIONAL
    iv_customer_id        TYPE zde_customer_id OPTIONAL
    RETURNING
    VALUE(rt_work_orders) TYPE tt_work_orders.

    METHODS update_work_order
      IMPORTING
        iv_work_order_id TYPE zde_work_order_id
        iv_status        TYPE zde_tfm_status
        iv_priority      TYPE zde_tfm_priority
        iv_description   TYPE zde_wo_description
      RETURNING
        VALUE(rv_updated) TYPE abap_bool.

    METHODS delete_work_order
      IMPORTING
        iv_work_order_id TYPE zde_work_order_id
      RETURNING
        VALUE(rv_deleted) TYPE abap_bool.

  PROTECTED SECTION.
  PRIVATE SECTION.

  METHODS lock_work_order
  IMPORTING
    iv_work_order_id TYPE zde_work_order_id
  RETURNING
    VALUE(rv_locked) TYPE abap_bool.

METHODS unlock_work_order
  IMPORTING
    iv_work_order_id TYPE zde_work_order_id.

ENDCLASS.



CLASS zcl_work_order_crud_handler IMPLEMENTATION.

  METHOD delete_work_order.

  rv_deleted = abap_false.

  " Read current work order status
  SELECT SINGLE status
    FROM ztfm_work_order
    WHERE work_order_id = @iv_work_order_id
    INTO @DATA(lv_status).

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  " Validate work order deletion
  DATA(lv_valid) = NEW zcl_work_order_validator( )->validate_delete_order(
    iv_work_order_id = iv_work_order_id
    iv_status        = lv_status ).

  IF lv_valid = abap_false.
    RETURN.
  ENDIF.

  " Delete work order
  DELETE FROM ztfm_work_order
    WHERE work_order_id = @iv_work_order_id.

  IF sy-subrc = 0.
    rv_deleted = abap_true.
  ENDIF.

  ENDMETHOD.

  METHOD read_work_order.

   CLEAR rs_work_order.

  SELECT SINGLE *
    FROM ztfm_work_order
    WHERE work_order_id = @iv_work_order_id
    INTO @rs_work_order.

  ENDMETHOD.

  METHOD update_work_order.

  rv_updated = abap_false.

  " Lock work order for concurrent updates
  DATA(lv_locked) = lock_work_order( iv_work_order_id ).

  IF lv_locked = abap_false.
    RETURN.
  ENDIF.

  " Read current work order status
  SELECT SINGLE status
    FROM ztfm_work_order
    WHERE work_order_id = @iv_work_order_id
    INTO @DATA(lv_current_status).

  IF sy-subrc <> 0.
    unlock_work_order( iv_work_order_id ).
    RETURN.
  ENDIF.

  " Validate current work order status
  DATA(lv_valid) = NEW zcl_work_order_validator( )->validate_update_order(
    iv_work_order_id = iv_work_order_id
    iv_status        = lv_current_status ).

  IF lv_valid = abap_false.
    unlock_work_order( iv_work_order_id ).
    RETURN.
  ENDIF.

  " Validate new status and priority
  DATA(lv_values_valid) = NEW zcl_work_order_validator( )->validate_status_and_priority(
    iv_status   = iv_status
    iv_priority = iv_priority ).

  IF lv_values_valid = abap_false.
    unlock_work_order( iv_work_order_id ).
    RETURN.
  ENDIF.

  " Update work order
  UPDATE ztfm_work_order
    SET status      = @iv_status,
        priority    = @iv_priority,
        description = @iv_description
    WHERE work_order_id = @iv_work_order_id.

  IF sy-subrc = 0.
    rv_updated = abap_true.
  ENDIF.

  " Release lock
  unlock_work_order( iv_work_order_id ).

  ENDMETHOD.

  METHOD create_work_order.

rv_created = abap_false.

  " Validate work order data
  DATA(lv_valid) = NEW zcl_work_order_validator( )->validate_create_order(
    iv_customer_id   = iv_customer_id
    iv_technician_id = iv_technician_id
    iv_priority      = iv_priority ).

  IF lv_valid = abap_false.
    RETURN.
  ENDIF.

  " Create work order
  DATA(ls_work_order) = VALUE ztfm_work_order(
    client        = sy-mandt
    work_order_id = iv_work_order_id
    customer_id   = iv_customer_id
    technician_id = iv_technician_id
    creation_date = cl_abap_context_info=>get_system_date( )
    status        = 'PE'
    priority      = iv_priority
    description   = iv_description ).

  INSERT ztfm_work_order FROM @ls_work_order.

  IF sy-subrc = 0.
    rv_created = abap_true.
  ENDIF.

  ENDMETHOD.

  METHOD read_work_orders.

  CLEAR rt_work_orders.

  SELECT *
    FROM ztfm_work_order
    WHERE ( @iv_creation_date_from IS INITIAL
            OR creation_date >= @iv_creation_date_from )
      AND ( @iv_creation_date_to IS INITIAL
            OR creation_date <= @iv_creation_date_to )
      AND ( @iv_status IS INITIAL
            OR status = @iv_status )
      AND ( @iv_customer_id IS INITIAL
            OR customer_id = @iv_customer_id )
    INTO TABLE @rt_work_orders.

  ENDMETHOD.

  METHOD lock_work_order.

  rv_locked = abap_false.

  TRY.

      DATA(lo_lock) = cl_abap_lock_object_factory=>get_instance(
        iv_name = 'EZTFM_WO' ).

      lo_lock->enqueue(
        it_parameter = VALUE #(
          ( name  = 'WORK_ORDER_ID'
            value = REF #( iv_work_order_id ) ) ) ).

      rv_locked = abap_true.

    CATCH cx_abap_foreign_lock.
      rv_locked = abap_false.

    CATCH cx_abap_lock_failure.
      rv_locked = abap_false.

  ENDTRY.


  ENDMETHOD.

  METHOD unlock_work_order.

  TRY.

      DATA(lo_lock) = cl_abap_lock_object_factory=>get_instance(
        iv_name = 'EZTFM_WO' ).

      lo_lock->dequeue( ).

    CATCH cx_abap_lock_failure.
      RETURN.
  ENDTRY.


  ENDMETHOD.

ENDCLASS.
