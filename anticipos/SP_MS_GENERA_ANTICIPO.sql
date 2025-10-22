SET TERM ^ ;

create or alter procedure ms_genera_anticipo (
    v_clave_cliente varchar(20), --Merchant ID
    importe numeric(15,2),  --Importe sin impuesto
    impuesto numeric(15,2), --Impuesto - IVA
    fechayhora varchar(25),
    v_fecha date,
    v_nombre_cliente varchar(200),
    v_tipo_persona char(1), --Moral o Física
    v_clave_regimen char(3), --Tipo de régimen fiscal
    rfc_cliente varchar(15),
    serie varchar(5), --Serie del anticipo (para control en microsip)
    folios varchar(10), --Folio del anticipo
    folion integer, --Folio numero
    fechayhoratimbrado varchar(100),
    forma_cobro_cc_id integer, 
    nombrexml varchar(100),
    descripcion varchar(200),
    xml blob sub_type 0 segment size 80,
    uuid varchar(60),
    horaemision time)
as
declare variable pctj_iva integer;
declare variable consecutivo integer;
declare variable sucursal_id integer;
declare variable nuevofoliocobro integer;
declare variable doctos_cc_id_cobro integer;
declare variable id_impuesto_iva integer;
declare variable impte_docto_cc_id integer;
declare variable ant_cc_id integer;
declare variable condicionpagoid integer;
declare variable lugarexpedicion integer;
declare variable foliofiscalid integer;
declare variable nombrecli varchar(100);
declare variable cfdiid integer;
declare variable forma_cobro_id integer;
declare variable docto_cc_id integer;
declare variable cliente_id integer;
begin
  /* Procedure Text */
sucursal_id=74375;


--Busca el ciente con el MerchantId
select c.cliente_id,c.nombre
from clientes c
join  claves_clientes d  on c.cliente_id=d.cliente_id
where d.clave_cliente=:V_clave_cliente into :cliente_id, :nombreCli;

IF(:cliente_id IS NULL) THEN
BEGIN
    EXECUTE PROCEDURE MS_REGISTRA_NUEVO_CLIENTE(:RFC_CLIENTE, :V_TIPO_PERSONA, :V_CLAVE_REGIMEN, V_CLAVE_CLIENTE, V_NOMBRE_CLIENTE)  ;
    select c.cliente_id,c.nombre
    from clientes c
    join  claves_clientes d  on c.cliente_id=d.cliente_id
    where d.clave_cliente=:V_clave_cliente into :cliente_id, :nombreCli;
END

--IF(:cliente_id is NOT NULL ) THEN
--begin
   --Si el cliente existe
   select le.lugar_expedicion_id
    from lugares_expedicion le
    where le.nombre= 'Matriz' into :lugarExpedicion;

    select cp.cond_pago_id
    from condiciones_pago cp
    where cp.nombre='CONTADO' into :CONDICIONPAGOID;

    docto_cc_id=GEN_ID(ID_DOCTOS,1);


    --DOCTO_CC es la direccion principal del anticipo
    INSERT INTO DOCTOS_CC (DOCTO_CC_ID, CONCEPTO_CC_ID, FOLIO, NATURALEZA_CONCEPTO,
    FECHA, HORA, CLAVE_CLIENTE, IMPORTE_COBRO, CLIENTE_ID, TIPO_CAMBIO, CANCELADO,
    APLICADO, DESCRIPCION, LUGAR_EXPEDICION_ID, CUENTA_CONCEPTO, COBRADOR_ID,
    FORMA_EMITIDA, CONTABILIZADO, CONTABILIZADO_GYP, COND_PAGO_ID, FECHA_DSCTO_PPAG,
    PCTJE_DSCTO_PPAG, FACTURA_MOSTRADOR, SISTEMA_ORIGEN, ESTATUS, ESTATUS_ANT, FECHA_APLICACION,
    ES_CFD, TIENE_ANTICIPO, MODALIDAD_FACTURACION, ENVIADO, FECHA_HORA_ENVIO, EMAIL_ENVIO,
    CFDI_CERTIFICADO, USO_CFDI, METODO_PAGO_SAT, INTEG_BA, CONTABILIZADO_BA, CUENTA_BAN_ID,
    REFER_MOVTO_BANCARIO, USUARIO_CREADOR, FECHA_HORA_CREACION, USUARIO_AUT_CREACION, USUARIO_ULT_MODIF,
    FECHA_HORA_ULT_MODIF, USUARIO_AUT_MODIF, USUARIO_CANCELACION, FECHA_HORA_CANCELACION,
    USUARIO_AUT_CANCELACION,sucursal_id)
    VALUES (:docto_cc_id, 30071, :folios, 'C', :V_FECHA,:HORAEMISION,
    :V_clave_cliente, 0, :cliente_id, 1, 'N', 'S', :DESCRIPCION, :lugarExpedicion, NULL, NULL, 'N',
    'N', 'N',:CONDICIONPAGOID, NULL, 0, NULL, 'CC', 'N', 'N', NULL, 'S', 'N', 'CFDI', 'N', NULL, NULL, 'S',
    'P01', 'PUE', 'N', 'N', NULL, NULL, 'SYSDBA', current_timestamp, NULL, 'SYSDBA', current_timestamp, NULL,
    NULL, NULL, NULL,:sucursal_id);



    --select first 1 dcc.docto_cc_id
    --from doctos_cc dcc
    --order by docto_cc_id
    --desc into :docto_cc_id;

    SELECT FIRST 1 FORMA_COBRO_CC_ID FROM FORMAS_COBRO_CC WHERE CLAVE_FISCAL =  :forma_cobro_cc_id INTO :FORMA_COBRO_ID;

    INSERT INTO FORMAS_COBRO_DOCTOS (FORMA_COBRO_DOC_ID, NOM_TABLA_DOCTOS, DOCTO_ID, FORMA_COBRO_ID, NUM_CTA_PAGO,
    CLAVE_SIS_FORMA_COB, REFERENCIA, IMPORTE) VALUES (-1, 'DOCTOS_CC', :docto_cc_id, :FORMA_COBRO_ID, NULL, 'CC', '', 0);

    ant_cc_id=GEN_ID(ID_DOCTOS,1);

    INSERT INTO ANTICIPOS_CC (ANTICIPO_CC_ID, CLIENTE_ID, FECHA, DESCRIPCION, ESTATUS, FOLIO, TIENE_IMPUESTO) VALUES
    (:ant_cc_id, :cliente_id, :v_fecha, 'Anticipos', 'P', :FOLIOS, 'S');

    
    INSERT INTO USOS_ANTICIPOS_CC (ANTICIPO_CC_ID, DOCTO_CC_ID, TIPO_USO, FECHA, IMPORTE, IMPUESTO,
    DOCTO_CC_ACR_ID, POR_DEPOSITAR, FECHA_HORA) VALUES (:ant_cc_id, :docto_cc_id, 'A',:v_fecha,
    :importe, :impuesto, NULL, 'N', :fechayhora);

    INSERT INTO VENCIMIENTOS_CARGOS_CC (DOCTO_CC_ID, FECHA_VENCIMIENTO, PCTJE_VEN) VALUES (:docto_cc_id,
    :v_fecha, 100);

    impte_docto_cc_id =  GEN_ID(ID_DOCTOS,1);

    --El importe considerado "neto"
    INSERT INTO IMPORTES_DOCTOS_CC (IMPTE_DOCTO_CC_ID, DOCTO_CC_ID, FECHA, CANCELADO, APLICADO, ESTATUS,
    TIPO_IMPTE, DOCTO_CC_ACR_ID, IMPORTE, IMPUESTO, IVA_RETENIDO, ISR_RETENIDO, DSCTO_PPAG, PCTJE_COMIS_COB)
    VALUES (:impte_docto_cc_id, :docto_cc_id,:v_fecha, 'N', 'S', 'N', 'C', :docto_cc_id, :importe, :impuesto, 0, 0, 0, 0);


    select imp.impuesto_id,PCTJE_IMPUESTO
    from impuestos imp where imp.nombre='IVA 16%' into :id_impuesto_iva,:pctj_iva;

    --El importe especificando el IVA
    INSERT INTO IMPORTES_DOCTOS_CC_IMPTOS (IMPTE_DOCTO_CC_IMPTO_ID, IMPTE_DOCTO_CC_ID, IMPUESTO_ID,
    IMPORTE, PCTJE_IMPUESTO, IMPUESTO) VALUES (-1, :impte_docto_cc_id, :id_impuesto_iva, :IMPORTE, :pctj_iva, :impuesto);

    cfdiid = GEN_ID(ID_DOCTOS,1);

    --Almacena el documento fiscal
    INSERT INTO REPOSITORIO_CFDI (CFDI_ID, MODALIDAD_FACTURACION, VERSION, UUID, NATURALEZA, TIPO_COMPROBANTE,
    TIPO_DOCTO_MSP, FOLIO, FECHA, RFC, TAXID, NOMBRE, IMPORTE, MONEDA, TIPO_CAMBIO, ES_PARCIALIDAD, NOM_ARCH,
    XML, REFER_GRUPO, FECHA_CANCELACION, SELLO_VALIDADO, USUARIO_VAL_SELLO, USUARIO_CREADOR, FECHA_HORA_CREACION,
    USUARIO_AUT_CREACION, USUARIO_ULT_MODIF, FECHA_HORA_ULT_MODIF, USUARIO_AUT_MODIF) VALUES (:cfdiid, 'CFDI', '3.3',
    :UUID, 'E', 'I', 'Anticipo', :folioN, :v_fecha, :rfc_cliente, NULL, :nombreCli, :importe+:impuesto, 'MXN', 0, 'N',
    :nombrexml,:XML, NULL, NULL, 'M', NULL, 'SYSDBA',current_timestamp, NULL, 'SYSDBA', current_timestamp, NULL);

    --select first 1 r.cfdi_id from REPOSITORIO_CFDI r order by r.cfdi_id desc into :cfdiid;

    select f.folios_fiscales_id from folios_fiscales f where f.serie=:serie and f.modalidad_facturacion='CFDI' into :folioFiscalID;

    INSERT INTO USOS_FOLIOS_FISCALES (USO_FOLIO_ID, FOLIOS_FISCALES_ID, FOLIO, FECHA, SISTEMA, DOCTO_ID, XML,
    PROV_CERT, FECHA_HORA_TIMBRADO, UUID, CFDI_ID) VALUES (-1, :folioFiscalID, :folioN, :v_fecha, 'CC',
    :docto_cc_id, :xml, 'CDIGITAL', :fechayhoraTimbrado, :uuid,:cfdiid);

    select cc.consecutivo from folios_conceptos cc
    where cc.concepto_id=11 and cc.sistema='CC' into :consecutivo;

    update folios_conceptos cx set cx.consecutivo=cx.consecutivo+1 where
    cx.concepto_id=11 and cx.sistema='CC' ;


    folios=lpad(cast(:consecutivo as varchar(9)), 9, '0');

    doctos_cc_id_cobro=GEN_ID(ID_DOCTOS,1);

    --Crea el cobro del anticipo
    INSERT INTO DOCTOS_CC (DOCTO_CC_ID, CONCEPTO_CC_ID, FOLIO, NATURALEZA_CONCEPTO,
    FECHA, HORA, CLAVE_CLIENTE, IMPORTE_COBRO, CLIENTE_ID, TIPO_CAMBIO, CANCELADO,
    APLICADO, DESCRIPCION, LUGAR_EXPEDICION_ID, CUENTA_CONCEPTO, COBRADOR_ID,
    FORMA_EMITIDA, CONTABILIZADO, CONTABILIZADO_GYP, COND_PAGO_ID, FECHA_DSCTO_PPAG,
    PCTJE_DSCTO_PPAG, FACTURA_MOSTRADOR, SISTEMA_ORIGEN, ESTATUS, ESTATUS_ANT, FECHA_APLICACION,
    ES_CFD, TIENE_ANTICIPO, MODALIDAD_FACTURACION, ENVIADO, FECHA_HORA_ENVIO, EMAIL_ENVIO,
    CFDI_CERTIFICADO, USO_CFDI, METODO_PAGO_SAT, INTEG_BA, CONTABILIZADO_BA, CUENTA_BAN_ID,
    REFER_MOVTO_BANCARIO, USUARIO_CREADOR, FECHA_HORA_CREACION, USUARIO_AUT_CREACION, USUARIO_ULT_MODIF,
    FECHA_HORA_ULT_MODIF, USUARIO_AUT_MODIF, USUARIO_CANCELACION, FECHA_HORA_CANCELACION,
    USUARIO_AUT_CANCELACION,sucursal_id) VALUES (:doctos_cc_id_cobro, 11, :folios, 'R', :V_FECHA,:HORAEMISION,
    :V_clave_cliente, 0, :cliente_id, 1, 'N', 'S', 'COBRO DEL '|| :DESCRIPCION , :lugarExpedicion, NULL, NULL, 'N',
    'N', 'N',:CONDICIONPAGOID, NULL, 0, NULL, 'CC', 'N', 'N', NULL, 'N', 'N', 'PREIMP', 'N', NULL, NULL, 'N',
    'P01', Null, 'N', 'N', NULL, NULL, 'SYSDBA', current_timestamp, NULL, 'SYSDBA', current_timestamp, NULL,
    NULL, NULL, NULL,:sucursal_id);

    INSERT INTO IMPORTES_DOCTOS_CC (IMPTE_DOCTO_CC_ID, DOCTO_CC_ID, FECHA, CANCELADO,
    APLICADO, ESTATUS, TIPO_IMPTE, DOCTO_CC_ACR_ID, IMPORTE, IMPUESTO, IVA_RETENIDO,
    ISR_RETENIDO, DSCTO_PPAG, PCTJE_COMIS_COB) VALUES (-1, :doctos_cc_id_cobro, :v_fecha,
    'N', 'S', 'N', 'R', :docto_cc_id, :importe + :impuesto, 0, 0, 0, 0, 0);

    INSERT INTO FORMAS_COBRO_DOCTOS (FORMA_COBRO_DOC_ID, NOM_TABLA_DOCTOS, DOCTO_ID, FORMA_COBRO_ID, NUM_CTA_PAGO,
    CLAVE_SIS_FORMA_COB, REFERENCIA, IMPORTE) VALUES (-1, 'DOCTOS_CC', :doctos_cc_id_cobro, :FORMA_COBRO_ID, NULL, 'CC', '', 0);

    INSERT INTO USOS_ANTICIPOS_CC (ANTICIPO_CC_ID, DOCTO_CC_ID, TIPO_USO, FECHA, IMPORTE, IMPUESTO,
    DOCTO_CC_ACR_ID, POR_DEPOSITAR, FECHA_HORA) VALUES (:ant_cc_id, :doctos_cc_id_cobro, 'C', :v_fecha,
    :importe, :impuesto,:docto_cc_id, 'N',:fechayhora);
       /*
    */

    --RESPONSE = 200;
/*
end 
ELSE
  begin
  EXCEPTION EX_DATO_ES_NULL 'No existe el usuario';
  RESPONSE = 0;
  end
  */

  suspend;
end^

SET TERM ; ^

/* Following GRANT statements are generated automatically */

GRANT USAGE ON SEQUENCE ID_DOCTOS TO PROCEDURE MS_GENERA_ANTICIPO;
GRANT SELECT ON CLIENTES TO PROCEDURE MS_GENERA_ANTICIPO;
GRANT SELECT ON CLAVES_CLIENTES TO PROCEDURE MS_GENERA_ANTICIPO;
GRANT EXECUTE ON PROCEDURE MS_REGISTRA_NUEVO_CLIENTE TO PROCEDURE MS_GENERA_ANTICIPO;
GRANT SELECT ON LUGARES_EXPEDICION TO PROCEDURE MS_GENERA_ANTICIPO;
GRANT SELECT ON CONDICIONES_PAGO TO PROCEDURE MS_GENERA_ANTICIPO;
GRANT INSERT ON DOCTOS_CC TO PROCEDURE MS_GENERA_ANTICIPO;
GRANT SELECT ON FORMAS_COBRO_CC TO PROCEDURE MS_GENERA_ANTICIPO;
GRANT INSERT ON FORMAS_COBRO_DOCTOS TO PROCEDURE MS_GENERA_ANTICIPO;
GRANT INSERT ON ANTICIPOS_CC TO PROCEDURE MS_GENERA_ANTICIPO;
GRANT INSERT ON USOS_ANTICIPOS_CC TO PROCEDURE MS_GENERA_ANTICIPO;
GRANT INSERT ON VENCIMIENTOS_CARGOS_CC TO PROCEDURE MS_GENERA_ANTICIPO;
GRANT INSERT ON IMPORTES_DOCTOS_CC TO PROCEDURE MS_GENERA_ANTICIPO;
GRANT SELECT ON IMPUESTOS TO PROCEDURE MS_GENERA_ANTICIPO;
GRANT INSERT ON IMPORTES_DOCTOS_CC_IMPTOS TO PROCEDURE MS_GENERA_ANTICIPO;
GRANT INSERT ON REPOSITORIO_CFDI TO PROCEDURE MS_GENERA_ANTICIPO;
GRANT SELECT ON FOLIOS_FISCALES TO PROCEDURE MS_GENERA_ANTICIPO;
GRANT INSERT ON USOS_FOLIOS_FISCALES TO PROCEDURE MS_GENERA_ANTICIPO;
GRANT SELECT,UPDATE ON FOLIOS_CONCEPTOS TO PROCEDURE MS_GENERA_ANTICIPO;

/* Existing privileges on this procedure */

GRANT EXECUTE ON PROCEDURE MS_GENERA_ANTICIPO TO SYSDBA;