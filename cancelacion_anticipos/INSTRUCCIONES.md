IMPORTANTE: 
    -Proceso destructivo, no ejecutar sin respaldo. 
    -Microsip debe estar cerrado y no se deben ejecutar otras instrucciones en el servidor simultaneamente


Pasos a seguir:

    -Crear las tablas y SP 

    -Colocar "0" en el valor de MS_SALDO_CANCELADO

    -DESACTIVAR: 
        -DOCTOS_CC_BEFUPD_0
        -IMPTES_DOCTOS_CC_BEFDEL_0
        -IMPTES_DOCTOS_CC_BEFUPD_0

    -Hacer los inserts de MS_ANTICIPOS_POR_CANCELAR

    -Ejecutar MS_CANCELA_ANTICIPO (No necesita parametros)

    Una vez que se termino de ejecutar el SP (comprobar que se insertaron registros en MS_POR_CANCELAR), ejecutar la instruccion: 

        UPDATE DOCTOS_CC SET CANCELADO = 'S' WHERE DOCTO_CC_ID IN(SELECT DOCTO_CC_ID FROM MS_POR_CANCELAR WHERE ID_DOCUMENT > 10);