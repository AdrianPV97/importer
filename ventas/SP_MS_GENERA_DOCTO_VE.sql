SET TERM ^ ;

create or alter procedure ms_genera_docto_ve (
    v_nombre_cliente varchar(40),
    v_folio_ap_ant varchar(9),
    v_nom_xml varchar(50),
    v_uuid_ap_ant varchar(40),
    v_xml_ap_ant blob sub_type 0 segment size 80,
    v_forma_cobro_cc_id integer,
    v_xml blob sub_type 0 segment size 80,
    v_uuid varchar(40),
    v_total_impuestos importe_monetario,
    v_importe_neto importe_monetario,
    v_descripcion varchar(200),
    v_folio char(9),
    v_clave_cliente varchar(20),
    lugar_exp_id integer,
    sucursal_id integer,
    almacen_id integer,
    v_fecha_proceso date,
    v_serie char(2))
returns (
    fac_vta_id integer,
    aplicacion integer,
    docto_cc_ins integer)
as
declare variable clave_cliente varchar(20);
declare variable folio_fiscal integer;
declare variable folios_fiscales_id integer;
declare variable credito_validacion integer;
declare variable usar_para_facturar si_no_s;
declare variable usar_para_envios si_no_s;
declare variable es_dir_ppal si_no_n;
declare variable via_embarque_id integer;
declare variable dir_cli_id integer;
declare variable hora_srvr time;
declare variable fecha_srvr date;
declare variable cliente_id integer;
declare variable rfc_curp varchar(18);
declare variable moneda_id integer;
declare variable cond_pago_id integer;
declare variable receptor_cfd varchar(30);
declare variable vendedor_id integer;
declare variable factura_id integer;
declare variable clave_fiscal integer;
declare variable forma_cobro_cc_id integer;
begin
  /* Procedure Text */

--Obtenemos la clave e ID del cliente
--SELECT FIRST 1 A.CLIENTE_ID, C.DIR_CLI_ID, C.VIA_EMBARQUE_ID, C.ES_DIR_PPAL, C.USAR_PARA_ENVIOS, C.USAR_PARA_FACTURAR, B.CLAVE_CLIENTE FROM DIRS_CLIENTES A
--JOIN CLAVES_CLIENTES B ON A.CLIENTE_ID = B.CLIENTE_ID
--JOIN DIRS_CLIENTES C ON A.CLIENTE_ID = C.CLIENTE_ID
--INTO :CLIENTE_ID, :DIR_CLI_ID, :VIA_EMBARQUE, :ES_DIR_PPAL, :USAR_PARA_ENVIOS, :USAR_PARA_FACTURAR, :CLAVE_CLIENTE  ;
--v_forma_cobro_cc_id = 3553; --Se debe cambiar en produccion

--:LUGAR_EXP_ID = 234; --Este es un valor de pruebas, cambiar por valor de produccion
--:SUCURSAL_ID = 384; --Este es un valor de pruebas, cambiar por valor de produccion
--:ALMACEN_ID = 19;

IF (:V_SERIE = 'PG') THEN
BEGIN
    :CLAVE_CLIENTE = 'PG';
END
ELSE
BEGIN
    :CLAVE_CLIENTE = :V_CLAVE_CLIENTE;
END


SELECT CLIENTE_ID FROM CLAVES_CLIENTES WHERE CLAVE_CLIENTE = :CLAVE_CLIENTE INTO :CLIENTE_ID    ;

--Obtiene los datos detallados del cliente
SELECT DIR_CLI_ID, VIA_EMBARQUE_ID, ES_DIR_PPAL, USAR_PARA_ENVIOS, USAR_PARA_FACTURAR, RFC_CURP
FROM DIRS_CLIENTES
WHERE CLIENTE_ID = :CLIENTE_ID AND ((0 = 0 AND ES_DIR_PPAL = 'S') OR  (0 <> 0 AND DIR_CLI_ID = 0))
INTO :DIR_CLI_ID, :VIA_EMBARQUE_ID, :ES_DIR_PPAL, :USAR_PARA_ENVIOS, :USAR_PARA_FACTURAR, :RFC_CURP;


--Este IF valida que el cliente exista y el tipo de cobro
/*
IF (:CLIENTE_ID IS NOT NULL) THEN
BEGIN
    SELECT CLIENTE_ID FROM CLIENTES WHERE CLIENTE_ID IN (1, 2, 3lista de clientes de credito) INTO :CREDITO_VALIDACION;
    IF (:CREDITO_VALIDACION IS NOT NULL) then
    BEGIN
        :FORMA_COBRO_CC_ID = 157;--Valor que tendra la forma de cobro de cr?dito
    END --Si es cliente de cr?dito
    ELSE
    BEGIN
      --:FORMA_COBRO_CC_ID = 3553;--Valor que tendra la forma de cobro de aplicacion de anticipos
    END
END --Si cliente ID != null   */



--Obtenemos la fecha y hora del servidor
SELECT FECHA, HORA FROM FECHA_SERVIDOR INTO :FECHA_SRVR, :HORA_SRVR;

--Obtenemos los detalles de la moneda
SELECT MONEDA_ID, COND_PAGO_ID, VENDEDOR_ID FROM CLIENTES WHERE CLIENTE_ID = :CLIENTE_ID INTO :MONEDA_ID, :COND_PAGO_ID, :VENDEDOR_ID;
IF(MONEDA_ID IS NULL) then
BEGIN
:MONEDA_ID = 1;
 :cond_pago_id = 866;
END
--Obtenemos los detalles de la condicion de pago  a travez de su ID
--SELECT COND_PAGO_ID, PCTJE_DSCTO_PPAG, DIAS_PPAG FROM CONDICIONES_PAGO WHERE COND_PAGO_ID = :COND_PAGO_ID INTO :COND_PAGO_ID, :PCTJE_DSCTO_PPAG, :DIAS_PPAG;


--Obtenemos detalles de la forma de cobro
SELECT FORMA_COBRO_CC_ID, CLAVE_FISCAL FROM FORMAS_COBRO_CC WHERE FORMA_COBRO_CC_ID = :V_FORMA_COBRO_CC_ID INTO  :FORMA_COBRO_CC_ID, :CLAVE_FISCAL;

:FACTURA_ID = GEN_ID(ID_DOCTOS,1);



--Insertamos el documento de ventas
INSERT INTO DOCTOS_VE (DOCTO_VE_ID, TIPO_DOCTO, FOLIO, SUCURSAL_ID, FECHA, HORA, CLAVE_CLIENTE, CLIENTE_ID, DIR_CLI_ID, DIR_CONSIG_ID, ALMACEN_ID, LUGAR_EXPEDICION_ID, TIPO_CAMBIO, TIPO_DSCTO, DSCTO_PCTJE, DSCTO_IMPORTE, ESTATUS, APLICADO,  FECHA_VIGENCIA_ENTREGA, ORDEN_COMPRA,
DESCRIPCION, IMPORTE_NETO,  TOTAL_IMPUESTOS, TOTAL_RETENCIONES, PESO_EMBARQUE, FLETES, OTROS_CARGOS, ACREDITAR_CXC,  SISTEMA_ORIGEN, COND_PAGO_ID,  FECHA_DSCTO_PPAG, PCTJE_DSCTO_PPAG,  VENDEDOR_ID, PCTJE_COMIS, VIA_EMBARQUE_ID,  IMPORTE_COBRO, DESCRIPCION_COBRO,
MODALIDAD_FACTURACION, IMPUESTO_SUSTITUIDO_ID, IMPUESTO_SUSTITUTO_ID, CARGAR_SUN, MONEDA_ID, ES_CFD, USO_CFDI, METODO_PAGO_SAT, CFDI_CERTIFICADO)
VALUES (
:FACTURA_ID, 'F', :V_FOLIO, :SUCURSAL_ID, :V_FECHA_PROCESO, :HORA_SRVR, :CLAVE_CLIENTE, :CLIENTE_ID, :DIR_CLI_ID, :DIR_CLI_ID,
:ALMACEN_ID, :LUGAR_EXP_ID, 1.000000, 'P', 0, 0, 'N', 'N', NULL, NULL, :V_DESCRIPCION,:V_IMPORTE_NETO, :V_TOTAL_IMPUESTOS,
0, 0, 0, 0, 'N', 'VE',
:COND_PAGO_ID,
NULL, 0, NULL, 0, NULL,
:V_IMPORTE_NETO, --Revisar
NULL, 'CFDI',
NULL,NULL, --Revisar
'S',
:MONEDA_ID, 'S', 'S01', 'PUE', 'S');

FAC_VTA_ID =   :FACTURA_ID;

INSERT INTO FORMAS_COBRO_DOCTOS(FORMA_COBRO_DOC_ID, NOM_TABLA_DOCTOS, DOCTO_ID,  FORMA_COBRO_ID, CLAVE_SIS_FORMA_COB) VALUES
(-1, 'DOCTOS_VE', :FACTURA_ID, :v_forma_cobro_cc_id, 'CC');

:FOLIO_FISCAL = GEN_ID(id_folio_temp, 1);

SELECT FOLIOS_FISCALES_ID FROM FOLIOS_FISCALES WHERE (MODALIDAD_FACTURACION = 'CFDI')  AND (SERIE = 'G')  INTO :FOLIOS_FISCALES_ID;


--Investigar valor V_FOLIO en este query
INSERT INTO USOS_FOLIOS_FISCALES(USO_FOLIO_ID, UUID, FOLIOS_FISCALES_ID, FOLIO, FECHA, SISTEMA, DOCTO_ID, XML)
VALUES(
    -1, :V_UUID, :FOLIOS_FISCALES_ID, :FOLIO_FISCAL , :V_FECHA_PROCESO, 'VE', :FACTURA_ID , :V_XML)     ;


 EXECUTE PROCEDURE MS_GENERA_DOCTO_CC_VE (:FACTURA_ID) RETURNING_VALUES :DOCTO_CC_INS;


 EXECUTE PROCEDURE MS_CREA_APLICACION_ANTICIPO(:DOCTO_CC_INS,  :V_XML_AP_ANT, V_NOM_XML, :V_NOMBRE_CLIENTE, :RFC_CURP, :V_UUID_AP_ANT, V_TOTAL_IMPUESTOS,
:V_IMPORTE_NETO, 'Aplicacion de Anticipo' || :v_descripcion, :V_FECHA_PROCESO, :V_FOLIO_AP_ANT, :CLIENTE_ID) RETURNING_VALUES :APLICACION;



  suspend;
end^

SET TERM ; ^

/* Following GRANT statements are generated automatically */

GRANT USAGE ON SEQUENCE ID_DOCTOS TO PROCEDURE MS_GENERA_DOCTO_VE;
GRANT USAGE ON SEQUENCE ID_FOLIO_TEMP TO PROCEDURE MS_GENERA_DOCTO_VE;
GRANT SELECT ON CLAVES_CLIENTES TO PROCEDURE MS_GENERA_DOCTO_VE;
GRANT SELECT ON DIRS_CLIENTES TO PROCEDURE MS_GENERA_DOCTO_VE;
GRANT EXECUTE ON PROCEDURE FECHA_SERVIDOR TO PROCEDURE MS_GENERA_DOCTO_VE;
GRANT SELECT ON CLIENTES TO PROCEDURE MS_GENERA_DOCTO_VE;
GRANT SELECT ON FORMAS_COBRO_CC TO PROCEDURE MS_GENERA_DOCTO_VE;
GRANT INSERT ON DOCTOS_VE TO PROCEDURE MS_GENERA_DOCTO_VE;
GRANT INSERT ON FORMAS_COBRO_DOCTOS TO PROCEDURE MS_GENERA_DOCTO_VE;
GRANT SELECT ON FOLIOS_FISCALES TO PROCEDURE MS_GENERA_DOCTO_VE;
GRANT INSERT ON USOS_FOLIOS_FISCALES TO PROCEDURE MS_GENERA_DOCTO_VE;
GRANT EXECUTE ON PROCEDURE MS_GENERA_DOCTO_CC_VE TO PROCEDURE MS_GENERA_DOCTO_VE;
GRANT EXECUTE ON PROCEDURE MS_CREA_APLICACION_ANTICIPO TO PROCEDURE MS_GENERA_DOCTO_VE;

/* Existing privileges on this procedure */

GRANT EXECUTE ON PROCEDURE MS_GENERA_DOCTO_VE TO SYSDBA;