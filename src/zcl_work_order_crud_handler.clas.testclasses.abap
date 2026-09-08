CLASS zcl_work_order_crud_test DEFINITION
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CLASS-DATA environment TYPE REF TO if_osql_test_environment.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    METHODS setup.
    METHODS teardown.

    METHODS test_create_work_order FOR TESTING.
    METHODS test_read_work_order   FOR TESTING.
    METHODS test_read_work_orders FOR TESTING.
    METHODS test_update_work_order FOR TESTING.
    METHODS test_delete_work_order FOR TESTING.
    METHODS test_delete_with_history_fails FOR TESTING.
    METHODS test_delete_not_pending_fails FOR TESTING.

ENDCLASS.

CLASS zcl_work_order_crud_test IMPLEMENTATION.

  METHOD test_create_work_order.

  DATA(lo_crud) = NEW zcl_work_order_crud_handler( ).

  DATA(lv_created) = lo_crud->create_work_order(
    iv_work_order_id = '0000000001'
    iv_customer_id   = '00000001'
    iv_technician_id = 'TECH0001'
    iv_priority      = 'A'
    iv_description   = 'Test work order' ).

  cl_abap_unit_assert=>assert_true(
    act = lv_created
    msg = 'Work order was not created successfully' ).

  ENDMETHOD.

  METHOD test_delete_work_order.

  DATA(lo_crud) = NEW zcl_work_order_crud_handler( ).

  " Create work order for delete test
  DATA(lv_created) = lo_crud->create_work_order(
    iv_work_order_id = '0000000001'
    iv_customer_id   = '00000001'
    iv_technician_id = 'TECH0001'
    iv_priority      = 'A'
    iv_description   = 'Test delete work order' ).

  cl_abap_unit_assert=>assert_true(
    act = lv_created
    msg = 'Work order could not be created for delete test' ).

  " Delete work order
  DATA(lv_deleted) = lo_crud->delete_work_order(
    iv_work_order_id = '0000000001' ).

  cl_abap_unit_assert=>assert_true(
    act = lv_deleted
    msg = 'Work order was not deleted successfully' ).

  " Read deleted work order
  DATA(ls_work_order) = lo_crud->read_work_order(
    iv_work_order_id = '0000000001' ).

  " Check that work order no longer exists
  cl_abap_unit_assert=>assert_initial(
    act = ls_work_order-work_order_id
    msg = 'Work order still exists after deletion' ).

  ENDMETHOD.

  METHOD test_read_work_order.

  DATA(lo_crud) = NEW zcl_work_order_crud_handler( ).

  " Create work order for read test
  DATA(lv_created) = lo_crud->create_work_order(
    iv_work_order_id = '0000000001'
    iv_customer_id   = '00000001'
    iv_technician_id = 'TECH0001'
    iv_priority      = 'A'
    iv_description   = 'Test read work order' ).

  cl_abap_unit_assert=>assert_true(
    act = lv_created
    msg = 'Work order could not be created for read test' ).

  " Read work order
  DATA(ls_work_order) = lo_crud->read_work_order(
    iv_work_order_id = '0000000001' ).

  " Check work order ID
  cl_abap_unit_assert=>assert_equals(
    act = ls_work_order-work_order_id
    exp = '0000000001'
    msg = 'Work order was not read correctly' ).

  ENDMETHOD.

  METHOD test_update_work_order.

    DATA(lo_crud) = NEW zcl_work_order_crud_handler( ).

  " Create work order directly in the SQL test double
  INSERT ztfm_work_order FROM @( VALUE #(
    client        = sy-mandt
    work_order_id = '0000000003'
    customer_id   = '00000001'
    technician_id = 'TECH0001'
    creation_date = cl_abap_context_info=>get_system_date( )
    status        = 'PE'
    priority      = 'A'
    description   = 'Antes de actualizar' ) ).

  cl_abap_unit_assert=>assert_subrc(
    msg = 'La orden de prueba no pudo insertarse' ).

  " Update work order
  DATA(lv_updated) = lo_crud->update_work_order(
    iv_work_order_id = '0000000003'
    iv_status        = 'CO'
    iv_priority      = 'B'
    iv_description   = 'Actualizada' ).

  cl_abap_unit_assert=>assert_true(
    act = lv_updated
    msg = 'La actualización debería tener éxito' ).

  " Read updated work order
  SELECT SINGLE *
    FROM ztfm_work_order
    WHERE work_order_id = '0000000003'
    INTO @DATA(ls_order).

  cl_abap_unit_assert=>assert_subrc(
    msg = 'La orden debe existir después de actualizarla' ).

  " Check updated values
  cl_abap_unit_assert=>assert_equals(
    act = ls_order-status
    exp = 'CO'
    msg = 'El estado debe ser CO' ).

  cl_abap_unit_assert=>assert_equals(
    act = ls_order-priority
    exp = 'B'
    msg = 'La prioridad debe ser B' ).

  cl_abap_unit_assert=>assert_equals(
    act = ls_order-description
    exp = 'Actualizada'
    msg = 'La descripción debe actualizarse' ).

  ENDMETHOD.

  METHOD class_setup.

  environment = cl_osql_test_environment=>create(
    i_dependency_list = VALUE #(
      ( 'ZTFM_CUSTOMER' )
      ( 'ZTFM_TECHNICIAN' )
      ( 'ZTFM_WORK_ORDER' )
      ( 'ZTFM_WO_HIST' )
    )
  ).

  ENDMETHOD.

  METHOD class_teardown.

  environment->destroy( ).

  ENDMETHOD.

  METHOD setup.

  " Clear test doubles before each test
  environment->clear_doubles( ).

  " Create test customer
  DATA lt_customer TYPE STANDARD TABLE OF ztfm_customer.

  lt_customer = VALUE #(
    ( client      = sy-mandt
      customer_id = '00000001'
      name        = 'Test Customer'
      address     = 'Test Address'
      phone       = '600000001' )
  ).

  environment->insert_test_data(
    i_data = lt_customer ).

  " Create test technician
  DATA lt_technician TYPE STANDARD TABLE OF ztfm_technician.

  lt_technician = VALUE #(
    ( client        = sy-mandt
      technician_id = 'TECH0001'
      name          = 'Test Technician'
      specialty     = 'Test Specialty' )
  ).

  environment->insert_test_data(
    i_data = lt_technician ).

  ENDMETHOD.

  METHOD teardown.

   " Clear test doubles after each test
  environment->clear_doubles( ).

  ENDMETHOD.

  METHOD test_delete_not_pending_fails.

  DATA(lo_crud) = NEW zcl_work_order_crud_handler( ).

  " Create completed work order
  INSERT ztfm_work_order FROM @( VALUE #(
    client        = sy-mandt
    work_order_id = '0000000006'
    customer_id   = '00000001'
    technician_id = 'TECH0001'
    creation_date = cl_abap_context_info=>get_system_date( )
    status        = 'CO'
    priority      = 'A'
    description   = 'Ya completada' ) ).

  cl_abap_unit_assert=>assert_subrc(
    msg = 'La orden de prueba no pudo insertarse' ).

  " Try to delete completed work order
  DATA(lv_deleted) = lo_crud->delete_work_order(
    iv_work_order_id = '0000000006' ).

  cl_abap_unit_assert=>assert_false(
    act = lv_deleted
    msg = 'No debe poder eliminarse una orden en estado CO' ).

  ENDMETHOD.

  METHOD test_delete_with_history_fails.

  DATA(lo_crud) = NEW zcl_work_order_crud_handler( ).

  " Create work order with history
  INSERT ztfm_work_order FROM @( VALUE #(
    client        = sy-mandt
    work_order_id = '0000000005'
    customer_id   = '00000001'
    technician_id = 'TECH0001'
    creation_date = cl_abap_context_info=>get_system_date( )
    status        = 'PE'
    priority      = 'A'
    description   = 'Con historial' ) ).

  cl_abap_unit_assert=>assert_subrc(
    msg = 'La orden de prueba no pudo insertarse' ).

  " Create history entry
  INSERT ztfm_wo_hist FROM @( VALUE #(
    client             = sy-mandt
    history_id         = '000000000001'
    work_order_id      = '0000000005'
    modification_date  = cl_abap_context_info=>get_system_date( )
    change_description = 'Cambio previo' ) ).

  cl_abap_unit_assert=>assert_subrc(
    msg = 'El historial de prueba no pudo insertarse' ).

  " Try to delete work order
  DATA(lv_deleted) = lo_crud->delete_work_order(
    iv_work_order_id = '0000000005' ).

  cl_abap_unit_assert=>assert_false(
    act = lv_deleted
    msg = 'No debe poder eliminarse una orden que tiene historial' ).

  ENDMETHOD.

  METHOD test_read_work_orders.

  DATA(lo_crud) = NEW zcl_work_order_crud_handler( ).

  " Create test work orders
  INSERT ztfm_work_order FROM TABLE @( VALUE #(
    ( client        = sy-mandt
      work_order_id = '0000000007'
      customer_id   = '00000001'
      technician_id = 'TECH0001'
      creation_date = '20260901'
      status        = 'PE'
      priority      = 'A'
      description   = 'Orden cliente 1 pendiente' )

    ( client        = sy-mandt
      work_order_id = '0000000008'
      customer_id   = '00000001'
      technician_id = 'TECH0001'
      creation_date = '20260903'
      status        = 'CO'
      priority      = 'B'
      description   = 'Orden cliente 1 completada' )

    ( client        = sy-mandt
      work_order_id = '0000000009'
      customer_id   = '00000002'
      technician_id = 'TECH0001'
      creation_date = '20260905'
      status        = 'PE'
      priority      = 'A'
      description   = 'Orden cliente 2 pendiente' ) ) ).

  cl_abap_unit_assert=>assert_subrc(
    msg = 'Las órdenes de prueba no pudieron insertarse' ).

  " Filter by customer
  DATA(lt_orders) = lo_crud->read_work_orders(
    iv_customer_id = '00000001' ).

  cl_abap_unit_assert=>assert_equals(
    act = lines( lt_orders )
    exp = 2
    msg = 'El filtro por cliente debería devolver 2 órdenes' ).

  " Filter by status
  lt_orders = lo_crud->read_work_orders(
    iv_status = 'CO' ).

  cl_abap_unit_assert=>assert_equals(
    act = lines( lt_orders )
    exp = 1
    msg = 'El filtro por estado CO debería devolver 1 orden' ).

  " Filter by date range
  lt_orders = lo_crud->read_work_orders(
    iv_creation_date_from = '20260902'
    iv_creation_date_to   = '20260904' ).

  cl_abap_unit_assert=>assert_equals(
    act = lines( lt_orders )
    exp = 1
    msg = 'El filtro por fecha debería devolver 1 orden' ).

  " Combined customer and status filters
  lt_orders = lo_crud->read_work_orders(
    iv_customer_id = '00000001'
    iv_status      = 'PE' ).

  cl_abap_unit_assert=>assert_equals(
    act = lines( lt_orders )
    exp = 1
    msg = 'La combinación de cliente y estado debería devolver 1 orden' ).

  ENDMETHOD.

ENDCLASS.
