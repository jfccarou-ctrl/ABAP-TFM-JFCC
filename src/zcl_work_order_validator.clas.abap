CLASS zcl_work_order_validator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS validate_create_order
      IMPORTING
        iv_customer_id   TYPE zde_customer_id
        iv_technician_id TYPE zde_technician_id
        iv_priority      TYPE zde_tfm_priority
      RETURNING
        VALUE(rv_valid) TYPE abap_bool.

    METHODS validate_update_order
      IMPORTING
        iv_work_order_id TYPE zde_work_order_id
        iv_status        TYPE zde_tfm_status
      RETURNING
        VALUE(rv_valid) TYPE abap_bool.

    METHODS validate_delete_order
      IMPORTING
        iv_work_order_id TYPE zde_work_order_id
        iv_status        TYPE zde_tfm_status
      RETURNING
        VALUE(rv_valid) TYPE abap_bool.

    METHODS validate_status_and_priority
      IMPORTING
        iv_status   TYPE zde_tfm_status
        iv_priority TYPE zde_tfm_priority
      RETURNING
        VALUE(rv_valid) TYPE abap_bool.

  PROTECTED SECTION.
    PRIVATE SECTION.

    METHODS check_customer_exists
      IMPORTING
        iv_customer_id TYPE zde_customer_id
      RETURNING
        VALUE(rv_exists) TYPE abap_bool.

    METHODS check_technician_exists
      IMPORTING
        iv_technician_id TYPE zde_technician_id
      RETURNING
        VALUE(rv_exists) TYPE abap_bool.

    METHODS check_order_exists
      IMPORTING
        iv_work_order_id TYPE zde_work_order_id
      RETURNING
        VALUE(rv_exists) TYPE abap_bool.

    METHODS check_order_history
      IMPORTING
        iv_work_order_id TYPE zde_work_order_id
      RETURNING
        VALUE(rv_exists) TYPE abap_bool.

ENDCLASS.

CLASS zcl_work_order_validator IMPLEMENTATION.
  METHOD check_customer_exists.

  rv_exists = abap_false.

  SELECT SINGLE customer_id
    FROM ztfm_customer
    WHERE customer_id = @iv_customer_id
    INTO @DATA(lv_customer_id).

  IF sy-subrc = 0.
    rv_exists = abap_true.
  ENDIF.

  ENDMETHOD.

  METHOD check_order_exists.

  rv_exists = abap_false.

  SELECT SINGLE work_order_id
    FROM ztfm_work_order
    WHERE work_order_id = @iv_work_order_id
    INTO @DATA(lv_work_order_id).

  IF sy-subrc = 0.
    rv_exists = abap_true.
  ENDIF.

  ENDMETHOD.

  METHOD check_order_history.

  rv_exists = abap_false.

  SELECT SINGLE history_id
    FROM ztfm_wo_hist
    WHERE work_order_id = @iv_work_order_id
    INTO @DATA(lv_history_id).

  IF sy-subrc = 0.
    rv_exists = abap_true.
  ENDIF.

  ENDMETHOD.

  METHOD check_technician_exists.

  rv_exists = abap_false.

  SELECT SINGLE technician_id
    FROM ztfm_technician
    WHERE technician_id = @iv_technician_id
    INTO @DATA(lv_technician_id).

  IF sy-subrc = 0.
    rv_exists = abap_true.
  ENDIF.

  ENDMETHOD.

  METHOD validate_create_order.

  rv_valid = abap_false.

  " Check if customer exists
  DATA(lv_customer_exists) = check_customer_exists( iv_customer_id ).

  IF lv_customer_exists = abap_false.
    RETURN.
  ENDIF.

  " Check if technician exists
  DATA(lv_technician_exists) = check_technician_exists( iv_technician_id ).

  IF lv_technician_exists = abap_false.
    RETURN.
  ENDIF.

  " Check if priority is valid
  IF iv_priority <> 'A' AND iv_priority <> 'B'.
    RETURN.
  ENDIF.

  rv_valid = abap_true.

  ENDMETHOD.

  METHOD validate_delete_order.

  rv_valid = abap_false.

  " Check if the work order exists
  DATA(lv_order_exists) = check_order_exists( iv_work_order_id ).

  IF lv_order_exists = abap_false.
    RETURN.
  ENDIF.

  " Check if the order status is Pending
  IF iv_status <> 'PE'.
    RETURN.
  ENDIF.

  " Check if the order has history entries
  DATA(lv_has_history) = check_order_history( iv_work_order_id ).

  IF lv_has_history = abap_true.
    RETURN.
  ENDIF.

  rv_valid = abap_true.

  ENDMETHOD.

  METHOD validate_status_and_priority.

  rv_valid = abap_false.

  " Validate status
  IF iv_status <> 'PE' AND iv_status <> 'CO'.
    RETURN.
  ENDIF.

  " Validate priority
  IF iv_priority <> 'A' AND iv_priority <> 'B'.
    RETURN.
  ENDIF.

  rv_valid = abap_true.   " <-- línea añadida


  ENDMETHOD.

  METHOD validate_update_order.

  rv_valid = abap_false.

  " Check if the work order exists
  DATA(lv_order_exists) = check_order_exists( iv_work_order_id ).

  IF lv_order_exists = abap_false.
    RETURN.
  ENDIF.

  " Check if the order status is editable
  IF iv_status <> 'PE'.
    RETURN.
  ENDIF.

  rv_valid = abap_true.

  ENDMETHOD.

ENDCLASS.
