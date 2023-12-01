*&---------------------------------------------------------------------*
*& Report ZPOLYLINE_TEST
*&---------------------------------------------------------------------*
*& Expected output for `BFoz5xJ67i1B1B7PzIhaxL7Y`
*& [
*&    (50.1022829, 8.6982122),
*&    (50.1020076, 8.6956695),
*&    (50.1006313, 8.6914960),
*&    (50.0987800, 8.6875156),
*& ]
*&---------------------------------------------------------------------*
REPORT zggar_polyline_global_class.

CONSTANTS: c_sample_polyline  TYPE text132 VALUE `BFoz5xJ67i1B1B7PzIhaxL7Y`.

SELECTION-SCREEN BEGIN OF BLOCK sb0 WITH FRAME TITLE TEXT-sb0.
  SELECTION-SCREEN SKIP.
* PARAMETERS: p_poly  TYPE text128 DEFAULT `BFoz5xJ67i1B1B7PzIhaxL7Y`.
  SELECTION-SCREEN: PUSHBUTTON /8(30) but1 USER-COMMAND onli.
  SELECTION-SCREEN SKIP.
SELECTION-SCREEN END   OF BLOCK sb0.

DATA:
  go_docking      TYPE REF TO cl_gui_docking_container,
  go_text_editor  TYPE REF TO cl_gui_textedit,
  gv_repid        TYPE syrepid,

  go_decoder      TYPE REF TO zcl_util_tm_polyline,

  gt_polylines_in TYPE TABLE OF tline-tdline,
  gv_polyline_in  TYPE string.

LOAD-OF-PROGRAM.
  " Pushbutton
  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
      name   = icon_execute_object
      text   = 'Execute'
      info   = 'Run program'
    IMPORTING
      result = but1
    EXCEPTIONS
      OTHERS = 99.

  " Text editor on the right-hand side
  gv_repid = sy-repid.

  go_docking = NEW cl_gui_docking_container(
      repid     = gv_repid
      dynnr     = sy-dynnr
      side      = cl_gui_docking_container=>dock_at_right
      caption   = 'Polyline'
      ratio     = 66
*     extension = 1070
  ).
  go_text_editor = NEW cl_gui_textedit( parent = go_docking ).
  go_text_editor->set_text_as_r3table( table = VALUE tdtab_c132( ( c_sample_polyline ) ) ).


START-OF-SELECTION.
  "------------------------------------------
  " Get Polyline input
  "------------------------------------------

  go_text_editor->get_text_as_r3table(
    IMPORTING
      table  = gt_polylines_in
    EXCEPTIONS
      OTHERS = 99
  ).

  LOOP AT gt_polylines_in ASSIGNING FIELD-SYMBOL(<lv_polyline_in>).
    CONCATENATE gv_polyline_in <lv_polyline_in>
           INTO gv_polyline_in IN CHARACTER MODE .
  ENDLOOP.

  CONDENSE gv_polyline_in NO-GAPS.

  IF gv_polyline_in IS INITIAL.
    MESSAGE e016(rp) WITH 'You MUST provide a polyline' DISPLAY LIKE 'I'.
    RETURN.
  ENDIF.

  "------------------------------------------
  " Process Decoding
  "------------------------------------------

  go_decoder = NEW zcl_util_tm_polyline( iv_encoded = gv_polyline_in ).

  CHECK go_decoder IS BOUND.

  go_decoder->decode(
    IMPORTING
      ev_version      = DATA(lv_version)
      ev_precision_2d = DATA(lv_precision_2d)
      ev_type_3d      = DATA(lv_type_3d)
      ev_precision_3d = DATA(lv_precision_3d)
      et_polyline     = DATA(lt_polyline)
  ).

END-OF-SELECTION.

  cl_demo_output=>new(
   )->begin_section( `Input`
   )->write_data( name = 'Encoded'        value = gv_polyline_in
   )->end_section(

   )->begin_section( `Header`
   )->write_data( name = 'Version'        value = lv_version
   )->write_data( name = 'Precision 2D'   value = lv_precision_2d
*  )->write_data( name = 'Support for 3D' value = |Type 3D: { lv_type_3d } / Precision 3D: { lv_precision_3d }|
   )->write_data( name = 'Type 3D'        value = lv_type_3d
   )->write_data( name = 'Precision 3D'   value = lv_precision_3d
   )->end_section(

   )->begin_section( `Polyline`
   )->write_data( lt_polyline
   )->end_section(

   )->display( ).
