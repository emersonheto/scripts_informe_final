USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [BANNER].[sp_AddInfFinalMemorandoRecuperadoFinalReportAp] 
FECHA	: 22/09/2025
AUTOR	: Brus Paucar (WAYTECH)
OBJETIVO: Registro de notas recuperadas para el documento Informe Final.
====================================================================================================*/

CREATE PROCEDURE [BANNER].[sp_AddInfFinalMemorandoRecuperadoFinalReportAp]
(
	 @Seccion VARCHAR(30),	 
	 @DNI VARCHAR(20),
	 @User_creacion VARCHAR(200),
	 @Accion INT,
     @ProgramCode VARCHAR(3),
     @p_IdDocumento VARCHAR(5),
     @p_IdDocumentoFinalReportAp VARCHAR(50)
)

AS 
SET NOCOUNT ON
BEGIN
	BEGIN TRY
        IF(@Accion=1)
            BEGIN
            
                    CREATE TABLE #RESULTADO ( 
                        Seccion  VARCHAR(20),
                        Codigo VARCHAR(10),
                        Apellidos_Nombres  VARCHAR(200),
                        Tipo_Programa  VARCHAR(100),
                        Nombre_Programa VARCHAR(200),
                        Curso VARCHAR(200),
                        Nota INT,
                        Estado_Academico VARCHAR(20)
                    )

                    DECLARE  @BDOracle VARCHAR(10)='BANNER';
                    DECLARE @QUERY NVARCHAR(MAX) = '
                    SELECT BLOQUE_MATRICULA,DNI,NOMBRE,TIPO,PROGRAM_DESC,NOMBRE_CURSO,GRDE_CODE,ESTADO_ASIGNATURA
                    FROM OPENQUERY ('+@BDOracle+',''
                    SELECT T1.BLOQUE_MATRICULA,T1.DNI,T1.NOMBRE,
                        (CASE WHEN T1.SUBJ_CODE = ''''PSDP'''' THEN ''''DIPLOMAS''''
                                WHEN T1.SUBJ_CODE = ''''PSEV'''' THEN ''''EVENTOS''''
                                WHEN T1.SUBJ_CODE = ''''PSMA'''' THEN ''''MAESTRIA''''
                                WHEN T1.SUBJ_CODE = ''''PSPA'''' THEN ''''PASANTIA''''
                                WHEN T1.SUBJ_CODE = ''''PSPE'''' THEN ''''PROGRAMAS DE ESPECIALIZACION''''
                                WHEN T1.SUBJ_CODE = ''''PSCC'''' THEN ''''CURSO CERRADO''''
                                WHEN T1.SUBJ_CODE = ''''PSCU'''' THEN ''''CURSO''''
                                WHEN T1.SUBJ_CODE = ''''PSDI'''' THEN ''''DIPLOMADO''''
                                WHEN T1.SUBJ_CODE = ''''PSDO'''' THEN ''''DOCTORADO'''' END) AS TIPO,
                        T1.PROGRAM_DESC,T1.NOMBRE_CURSO,T1.GRDE_CODE,NVL(T1.ESTADO_ASIGNATURA,'''' '''') AS ESTADO_ASIGNATURA
                    FROM BANINST1.SZVALDI T1
                    WHERE T1.DNI=''''' + @DNI + ''''' 
                    AND T1.PROGRAM_CODE=''''' + @programCode + '''''
                    AND SUBSTR(T1.AREA_CODE,4,1)<>''''C''''
                    AND T1.ESTADO_ASIGNATURA=''''Aprobado''''
                    AND EXISTS (
                        SELECT 1
                        FROM BANINST1.SZVALDI T2
                        WHERE
                            T2.DNI = T1.DNI
                            AND T2.PROGRAM_CODE = T1.PROGRAM_CODE
                            AND T2.ASIGNATURA = T1.ASIGNATURA
                            AND T2.ESTADO_ASIGNATURA = ''''Desaprobado''''
                    )
                    ORDER BY
                        T1.ASIGNATURA
                    ''
                    )'
                    INSERT INTO #RESULTADO
                    EXEC (@QUERY)
                    
                    INSERT INTO dbo.[tblInfFinalMemorandumFinalReportAp] (
                        Seccion,                        
                        Codigo, 
                        ApellidosNombres, 
                        TipoPrograma, 
                        Programa, 
                        Asignatura, 
                        EstadoAcademico, 
                        NotaFinal, 
                        FechaRegistro, 
                        FechaEdicion, 
                        UsuarioCreacion, 
                        ProgramaCodigo, 
                        IdDocumentoFinalReportAp
                    )
                    SELECT 
                        @Seccion AS Seccion,                        
                        Codigo AS Codigo,
                        Apellidos_Nombres AS ApellidosNombres,
                        Tipo_Programa AS TipoPrograma,
                        Nombre_Programa AS Programa,
                        Curso AS Asignatura,
                        ISNULL(Estado_Academico,'') AS EstadoAcademico,
                        ISNULL(Nota,0) AS NotaFinal,
                        GETDATE() AS FechaRegistro,
                        NULL AS FechaEdicion,
                        @User_creacion AS UsuarioCreacion,
                        @ProgramCode AS ProgramaCodigo,
                        @p_IdDocumentoFinalReportAp AS IdDocumentoFinalReportAp
                    FROM #RESULTADO 
                    ORDER BY 1, 2;

                    DROP TABLE #RESULTADO
                        SELECT 0 AS 'NRO_RESPUESTA',
                            'SE INSERT� CORRECTAMENTE LOS PARTICIPANTES' AS 'MSG'
            END
        ELSE IF (@Accion=2)
            BEGIN
            DELETE FROM dbo.[tblInfFinalMemorandumFinalReportAp] WHERE IdDocumentoFinalReportAp=@p_IdDocumentoFinalReportAp
            SELECT 0 AS 'NRO_RESPUESTA',
                'SE ELIMIN� CORRECTAMENTE RESULTADO DE NOTAS DE LOS PARTICIPANTES' AS 'MSG'
            END
            END TRY
            BEGIN CATCH
                DECLARE	@ErrorMessage VARCHAR(4000),
                        @ErrorSeverity INT,
                        @ErrorState INT;
                SELECT	@ErrorMessage =ERROR_MESSAGE(),
                        @ErrorSeverity=ERROR_SEVERITY(),
                        @ErrorState=ERROR_STATE();
                        RAISERROR(@ErrorMessage,@ErrorSeverity,@ErrorState);
                        SELECT @ErrorMessage AS status
            END CATCH
        END
 

