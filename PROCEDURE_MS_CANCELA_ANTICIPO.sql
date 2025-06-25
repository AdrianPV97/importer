SET TERM ^ ;

create or alter procedure ms_cancela_anticipo (
    v_impuesto integer,
    v_importe integer,
    v_docto_cc_id integer,
    v_anticipo_id integer)
as
begin
INSERT INTO USOS_ANTICIPOS_CC
(ANTICIPO_CC_ID, DOCTO_CC_ID, TIPO_USO, FECHA, IMPORTE, IMPUESTO, IMPUESTO_RET, DOCTO_CC_ACR_ID, POR_DEPOSITAR, FECHA_HORA)
VALUES
(:V_ANTICIPO_ID, :V_DOCTO_CC_ID, 'D', CURRENT_DATE, :V_IMPORTE, :V_IMPUESTO, 0.0, :V_DOCTO_CC_ID, 'N', CURRENT_DATE);
  suspend;
end^

SET TERM ; ^

/* Following GRANT statements are generated automatically */

GRANT INSERT ON USOS_ANTICIPOS_CC TO PROCEDURE MS_CANCELA_ANTICIPO;

/* Existing privileges on this procedure */

GRANT EXECUTE ON PROCEDURE MS_CANCELA_ANTICIPO TO SYSDBA;