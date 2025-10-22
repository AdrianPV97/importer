SET TERM ^ ;

create or alter procedure ms_aplica_anticipo_2 (
    v_docto_cc_vent_id integer,
    v_impuesto numeric(15,2),
    v_importe numeric(15,2),
    v_docto_cc_id_ant integer,
    v_folio char(9))
as
declare variable anticipo_cc_id integer;
begin

select ant.anticipo_cc_id from anticipos_cc ant where ant.folio= :V_FOLIO into :anticipo_cc_id;

INSERT INTO USOS_ANTICIPOS_CC (ANTICIPO_CC_ID, DOCTO_CC_ID, TIPO_USO, FECHA, IMPORTE, IMPUESTO,
DOCTO_CC_ACR_ID,
POR_DEPOSITAR, FECHA_HORA) VALUES (
:anticipo_cc_id,
:V_DOCTO_CC_ID_ANT,--Aqui va el ID del anticipo, debe ser   naturaleza R
'P', current_date, :V_IMPORTE, :V_IMPUESTO,
:V_DOCTO_CC_VENT_ID, --DOCTO_CC CREADO A PARTIR DE LA VENTA
'N', current_timestamp);






  suspend;
end^

SET TERM ; ^

/* Following GRANT statements are generated automatically */

GRANT SELECT ON ANTICIPOS_CC TO PROCEDURE MS_APLICA_ANTICIPO_2;
GRANT INSERT ON USOS_ANTICIPOS_CC TO PROCEDURE MS_APLICA_ANTICIPO_2;

/* Existing privileges on this procedure */

GRANT EXECUTE ON PROCEDURE MS_APLICA_ANTICIPO_2 TO SYSDBA;