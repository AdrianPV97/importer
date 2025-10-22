/******************************************************************************/
/*                Sirve para la aplicacion de anticipos                       */
/******************************************************************************/

/******************************************************************************/
/*        Following SET SQL DIALECT is just for the Database Comparer         */
/******************************************************************************/
SET SQL DIALECT 3;



/******************************************************************************/
/*                                   Tables                                   */
/******************************************************************************/



CREATE TABLE CFDI_VENTAS_RELACIONADOS (
    IDLOCAL          CHAR(50) NOT NULL,
    IDCFDIVENTAS     VARCHAR(50),
    FECHAPROCESO     DATE NOT NULL,
    UUIDRELACIONADO  CHAR(50) NOT NULL,
    SUBTOTAL         NUMERIC(18,2),
    SERIE            VARCHAR(10),
    FOLIO            VARCHAR(20),
    IMPUESTO         NUMERIC(18,2)
);



/******************************************************************************/
/*                                Primary keys                                */
/******************************************************************************/

ALTER TABLE CFDI_VENTAS_RELACIONADOS ADD CONSTRAINT PK_CFDIVENTASRELACIONADOS_ID PRIMARY KEY (IDLOCAL);


/******************************************************************************/
/*                                  Triggers                                  */
/******************************************************************************/



SET TERM ^ ;



/******************************************************************************/
/*                            Triggers for tables                             */
/******************************************************************************/



/* Trigger: CFDI_VENTAS_RELACIONADOS_AU0 */
CREATE OR ALTER TRIGGER CFDI_VENTAS_RELACIONADOS_AU0 FOR CFDI_VENTAS_RELACIONADOS
ACTIVE AFTER UPDATE POSITION 0
AS
begin
  /* Trigger text */
  /*
  EXECUTE PROCEDURE MS_APLICA_ANTICIPO_2(
    REVISAR, --Preguntar a travez de que dato se estan relacionando
    NEW.impuesto, 
    NEW.subtotal,
    REVISAR, --Preguntar como se relacionan
    NEW.FOLIO
  )
  */
end
^
SET TERM ; ^



/******************************************************************************/
/*                                 Privileges                                 */
/******************************************************************************/
