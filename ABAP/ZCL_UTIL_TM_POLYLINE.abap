class ZCL_UTIL_TM_POLYLINE definition
  public
  final
  create public .

public section.

  types TY_VERSION type STRING .
  types TY_TYPE_3D type I .
  types TY_NUM type INT8 .
  types:
    ty_t_num  TYPE STANDARD TABLE OF ty_num WITH NON-UNIQUE DEFAULT KEY .
  types:
    BEGIN OF ty_s_decoded,
        lat TYPE decfloat34,
        lng TYPE decfloat34,
        z   TYPE decfloat34,
      END    OF ty_s_decoded .
  types:
    ty_t_decoded TYPE STANDARD TABLE OF ty_s_decoded WITH NON-UNIQUE DEFAULT KEY .

  constants C_FORMAT_VERSION type I value 1 ##NO_TEXT.
  constants:
    BEGIN OF gc_s_type_3d,
        absent     TYPE ty_type_3d VALUE 0,
        level      TYPE ty_type_3d VALUE 1,
        altitude   TYPE ty_type_3d VALUE 2,
        elevation  TYPE ty_type_3d VALUE 3,
        reserved_1 TYPE ty_type_3d VALUE 4,
        reserved_2 TYPE ty_type_3d VALUE 5,
        custom_1   TYPE ty_type_3d VALUE 6,
        custom_2   TYPE ty_type_3d VALUE 7,
      END    OF gc_s_type_3d .

  methods CONSTRUCTOR
    importing
      !IV_ENCODED type CLIKE .
  methods DECODE
    exporting
      !EV_VERSION type TY_VERSION
      !EV_PRECISION_2D type I
      !EV_TYPE_3D type TY_TYPE_3D
      !EV_PRECISION_3D type I
      !ET_POLYLINE type TY_T_DECODED .
protected section.

  constants C_ENCODING type STRING value `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_` ##NO_TEXT.
  data:
    mt_decoding        TYPE STANDARD TABLE OF i .       " too long to be a constant
  data MT_UNSIGNED_VALUES type TY_T_NUM .
  data MV_ENCODED type STRING .

  methods DECODE_CHAR
    importing
      !IV_CHARACTER type C
    returning
      value(RV_DECODED) type TY_NUM .
  methods DECODE_HEADER
    exporting
      !EV_VERSION type TY_VERSION
      !EV_PRECISION_2D type I
      !EV_TYPE_3D type TY_TYPE_3D
      !EV_PRECISION_3D type I .
  methods TO_SIGNED
    importing
      !IV_UNSIGNED type TY_NUM
    returning
      value(RV_SIGNED) type TY_NUM .
  methods DECODE_UNSIGNED_VALUES
    importing
      !IV_ENCODED type CLIKE
    exporting
      !ET_DECODED type TY_T_NUM .
ENDCLASS.



CLASS ZCL_UTIL_TM_POLYLINE IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_UTIL_TM_POLYLINE->CONSTRUCTOR
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ENCODED                     TYPE        CLIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
METHOD constructor.
************************************************************************
* Author : HRC Software (Guillaume G.)
* Date   : 1-dec-2023
* Website: https://hrc-software.com
*
* This is an ABAP-port of the JS code from:
*    https://github.com/heremaps/flexible-polyline/
************************************************************************

  CONSTANTS:
    c_decoding1 TYPE string VALUE
      `-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,`
    & `-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,`
    & `-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,`
    & `-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,`
    & `-1,-1,-1,-1,-1,62,-1,-1,52,53,`
    & `54,55,56,57,58,59,60,61,-1,-1,`
    & `-1,-1,-1,-1,-1,`,
    c_decoding2 TYPE string VALUE
                     `0,1,2,3,4,`
    & `5,6,7,8,9,10,11,12,13,14,`
    & `15,16,17,18,19,20,21,22,23,24,`
    & `25,-1,-1,-1,-1,63,-1,26,27,28,`
    & `29,30,31,32,33,34,35,36,37,38,`
    & `39,40,41,42,43,44,45,46,47,48,`
    & `49,50,51`.

  DATA:
    lt_tokens  TYPE TABLE OF string.

  " Define DECODING table
  SPLIT |{ c_decoding1 }{ c_decoding2 }| AT ',' INTO TABLE lt_tokens.
  mt_decoding[] = lt_tokens[].

  " Save encoded polyline
  mv_encoded    = iv_encoded.

  " Prepare processing
  decode_unsigned_values(
    EXPORTING
      iv_encoded = mv_encoded
    IMPORTING
      et_decoded = mt_unsigned_values
  ).

ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_UTIL_TM_POLYLINE->DECODE
* +-------------------------------------------------------------------------------------------------+
* | [<---] EV_VERSION                     TYPE        TY_VERSION
* | [<---] EV_PRECISION_2D                TYPE        I
* | [<---] EV_TYPE_3D                     TYPE        TY_TYPE_3D
* | [<---] EV_PRECISION_3D                TYPE        I
* | [<---] ET_POLYLINE                    TYPE        TY_T_DECODED
* +--------------------------------------------------------------------------------------</SIGNATURE>
METHOD decode.
************************************************************************
* This is an ABAP-port of the JS code from:
*    https://github.com/heremaps/flexible-polyline/
************************************************************************

*======================================================================*
* Every input integer is converted in one or more chunks of 6 bits
*   where the highest bit is a control bit
*   while the remaining five store actual data.
*
* Each of these chunks gets encoded separately
*   as a printable character using the following character set:
*
* ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_
*
* Where A represents 0 and _ represents 63.
*======================================================================*

  DATA:
    lt_unsigned_values LIKE mt_unsigned_values[],

    lv_unsigned_num    TYPE ty_num,
    lv_signed_num      TYPE ty_num,

    lv_latitude        TYPE decfloat34,
    lv_longitude       TYPE decfloat34,
    lv_dim_3d          TYPE decfloat34,

    lv_last_latitude   TYPE decfloat34,
    lv_last_longitude  TYPE decfloat34,
    lv_last_dim_3d     TYPE decfloat34,

    lv_factor_2d       TYPE ty_num,
    lv_factor_3d       TYPE ty_num.

  FIELD-SYMBOLS:
    <lv_unsigned_value>  LIKE LINE OF lt_unsigned_values.

  DEFINE shift_array.
    CLEAR: lv_unsigned_num.

    READ TABLE lt_unsigned_values INTO lv_unsigned_num INDEX 1.
    &1 = to_signed( lv_unsigned_num ).

    DELETE lt_unsigned_values INDEX 1.
  END-OF-DEFINITION.

  " Header decoding
  decode_header(
    IMPORTING
      ev_version      = ev_version
      ev_precision_2d = ev_precision_2d
      ev_type_3d      = ev_type_3d
      ev_precision_3d = ev_precision_3d
  ).

  "--------------------------------------------
  " Process polyline
  "--------------------------------------------

  " Preparation
  lv_factor_2d = 10 ** ev_precision_2d.
  lv_factor_3d = 10 ** ev_precision_3d.

  " By group of 2 OR 3
  lt_unsigned_values[] = mt_unsigned_values[].

  DELETE lt_unsigned_values FROM 1 TO 2.  " remove Header

  WHILE lines( lt_unsigned_values ) > 0.
    shift_array: lv_latitude.
    shift_array: lv_longitude.

    lv_latitude  = lv_latitude  / lv_factor_2d.
    lv_longitude = lv_longitude / lv_factor_2d.

    lv_last_latitude  = lv_last_latitude  + lv_latitude.
    lv_last_longitude = lv_last_longitude + lv_longitude.

    IF ev_type_3d EQ gc_s_type_3d-absent.
      APPEND VALUE #(
        lat = lv_last_latitude
        lng = lv_last_longitude
      ) TO et_polyline.
    ELSE.
      shift_array: lv_dim_3d.
      lv_dim_3d = lv_dim_3d / lv_factor_3d.

      lv_last_dim_3d = lv_last_dim_3d + lv_dim_3d.

      APPEND VALUE #(
        lat = lv_last_latitude
        lng = lv_last_longitude
        z   = lv_last_dim_3d
      ) TO et_polyline.

    ENDIF.
  ENDWHILE.

ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZCL_UTIL_TM_POLYLINE->DECODE_CHAR
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_CHARACTER                   TYPE        C
* | [<-()] RV_DECODED                     TYPE        TY_NUM
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD DECODE_CHAR.
    DATA: lv_x_value     TYPE x,
          lv_p_value     TYPE p,
          lv_x_value2(2) TYPE x,
          ec_value2      TYPE c.

    FIELD-SYMBOLS: <iv_character> TYPE any.

    ASSIGN iv_character TO <iv_character> CASTING TYPE x.
    CHECK <iv_character> IS ASSIGNED.

    lv_x_value = <iv_character>.
    ADD 0 TO lv_x_value.
    MOVE lv_x_value TO lv_p_value.
*     MOVE lv_p_value TO lv_x_value2.
*     DATA() = cl_abap_conv_in_ce=>uccp( uccp = lv_x_value2 ).

    rv_decoded = mt_decoding[ lv_p_value + 1 ]. " A -> 0, B-> 1, and so on...

*     WRITE : / |Character '{ iv_character }' -> Decoded = { rv_decoded }|.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZCL_UTIL_TM_POLYLINE->DECODE_HEADER
* +-------------------------------------------------------------------------------------------------+
* | [<---] EV_VERSION                     TYPE        TY_VERSION
* | [<---] EV_PRECISION_2D                TYPE        I
* | [<---] EV_TYPE_3D                     TYPE        TY_TYPE_3D
* | [<---] EV_PRECISION_3D                TYPE        I
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD DECODE_HEADER.
    DATA: lv_header_content TYPE i.

    FIELD-SYMBOLS: <lv_header_content> TYPE any.

    "--------------------------------------------
    " Processing
    "--------------------------------------------

    ev_version        = mt_unsigned_values[ 1 ].
    lv_header_content = mt_unsigned_values[ 2 ].

    " Header content is encoded as an unsigned varint
    ASSIGN lv_header_content TO <lv_header_content> CASTING TYPE x.
    CHECK <lv_header_content> IS ASSIGNED.

    " Rewrite using Modulo instead of Bit-Shifting
    ev_precision_2d = lv_header_content MOD 16.   lv_header_content = ( lv_header_content - ev_precision_2d ) / 16.
    ev_type_3d      = lv_header_content MOD 8.    lv_header_content = ( lv_header_content - ev_type_3d )      / 8.
    ev_precision_3d = lv_header_content MOD 16.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZCL_UTIL_TM_POLYLINE->DECODE_UNSIGNED_VALUES
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ENCODED                     TYPE        CLIKE
* | [<---] ET_DECODED                     TYPE        TY_T_NUM
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD DECODE_UNSIGNED_VALUES.
  " For polyline 'Bw8BhGkCg-impzk4v21M', it should produce:
  "    1
  "    1936
  "    193                  -> -97
  "    68                   -> 34
  "    456780840707492800   -> 228.390420353746407
    DATA:
      lv_len       TYPE i,
      lv_offset    TYPE sy-index,
      lv_character TYPE c LENGTH 1,
      lv_bit       TYPE c LENGTH 1,
      lv_bit_pos   TYPE sy-index,     " from a pure Binary perspective
      lv_bit_index TYPE sy-index,
      lv_result    TYPE ty_num,
      lv_chunk     TYPE ty_num,
      lv_value     TYPE ty_num,
      lv_shift     TYPE ty_num.

    FIELD-SYMBOLS: <lv_value> TYPE any.

    lv_len = strlen( iv_encoded ).

    DO lv_len TIMES.
      " Clean up!
      CLEAR:
        lv_offset,
        lv_character,
        lv_bit_pos,
        lv_bit_index,
        lv_bit,
        lv_value,
        lv_chunk.

      " Process character
      lv_offset    = sy-index - 1.             " -1 for the 0-indexing of strings
      lv_character = iv_encoded+lv_offset(1).

      lv_value = decode_char( lv_character ).
      ASSIGN lv_value TO <lv_value> CASTING TYPE x.

      " Processing this chunk of 5 bits
      "   8th bit is actually the least-significant bit
      WHILE lv_bit_pos < 5.
        lv_bit_index = 8 - lv_bit_pos.

        GET BIT lv_bit_index OF <lv_value> INTO lv_bit.
        lv_chunk += lv_bit * 2 ** lv_bit_pos.

        ADD 1 TO lv_bit_pos.
      ENDWHILE.

      lv_chunk = lv_chunk * 2 ** lv_shift.
      ADD lv_chunk TO lv_result.

      " Determine whether to continue OR stop based on 6th bit
      GET BIT 3 OF <lv_value> INTO lv_bit.    " 3rd bit is the 6th (as 8th is LSB)

      CASE lv_bit.
        WHEN 0.
          APPEND lv_result TO et_decoded.
          lv_result = 0.
          lv_shift  = 0.

        WHEN 1.
          lv_shift = lv_shift + 5.
      ENDCASE.
    ENDDO.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZCL_UTIL_TM_POLYLINE->TO_SIGNED
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_UNSIGNED                    TYPE        TY_NUM
* | [<-()] RV_SIGNED                      TYPE        TY_NUM
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD TO_SIGNED.
    IF iv_unsigned MOD 2 EQ 1.
      rv_signed = iv_unsigned / 2 * -1.
    ELSE.
      rv_signed = iv_unsigned / 2.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
