use BDUCCI;
go

DECLARE @Procedimiento NVARCHAR(MAX);
DECLARE @Definicion NVARCHAR(MAX);
DECLARE @NuevoScript NVARCHAR(MAX);

DECLARE ProcedimientosCursor CURSOR FOR
SELECT '[dbo].[sp_ResultadoNotasParticipantesEntidad]' AS Nombre
UNION ALL
SELECT '[dbo].[sp_ResultadoNotasParticipantes]'
UNION ALL
SELECT '[dbo].[sp_NotaAlumnoRecuperado]'
UNION ALL
SELECT '[dbo].[sp_ReporteDocumentosEmitidos]'
UNION ALL
SELECT '[dbo].[sp_SeccionCertificar]'
UNION ALL
SELECT '[dbo].[sp_FiltrarSeccionesParaEntrevistas]'
-- UNION ALL
-- SELECT '[dbo].[sp_ResultadoEstadoAlumnoEntidad]'
-- UNION ALL
-- SELECT '[dbo].[sp_ResultadoEstadoAlumno]'
UNION ALL
SELECT '[dbo].[sp_ResultadoTipoAlumno]'
UNION ALL
SELECT '[dbo].[sp_ResultadoTipoAlumnoEntidad]'
UNION ALL
SELECT '[dbo].[sp_ResultadoAsistenciasParticipantes]'
UNION ALL
SELECT '[dbo].[sp_ResultadoAsistenciasParticipantesCertificacion]'
UNION ALL
SELECT '[dbo].[sp_ResultadoAsistenciasParticipantesEntidad]'
UNION ALL
SELECT '[dbo].[sp_ResultadoOrdenMerito]'
UNION ALL
SELECT '[dbo].[sp_ResultadoOrdenMeritoEntidad]'
UNION ALL
SELECT '[dbo].[sp_CertificacionPrograma]'
UNION ALL
SELECT '[dbo].[sp_CertificacionProgramaEntidad]'
UNION ALL
SELECT '[dbo].[sp_ConstanciaParticipacion]'
UNION ALL
SELECT '[dbo].[sp_ConstanciaParticipacionEntidad]'
UNION ALL
SELECT '[dbo].[sp_DatosAlumno]'
UNION ALL
SELECT '[dbo].[sp_DatosAlumnoEntidad]'
UNION ALL
SELECT '[dbo].[SP_BuscaEstudiantexSeccion]'
UNION ALL
SELECT '[dbo].[sp_BuscaEstudiantexSeccionCertificacion]'
UNION ALL
SELECT '[dbo].[sp_ResultadoNotasParticipantesCursos]'
UNION ALL
SELECT '[dbo].[sp_ResultadoNotasParticipantesCursosEntidad]'
UNION ALL
SELECT '[dbo].[sp_MemorandoRecuperado]'
UNION ALL
SELECT '[dbo].[sp_MemoRecuperadoCabecera]'
UNION ALL
SELECT '[dbo].[sp_MemorandoRecuperadoAsignatura]'
UNION ALL
SELECT '[dbo].[sp_ProgramacionEquipoDocente]'
UNION ALL
SELECT '[dbo].[sp_ProgramacionEquipoDocenteEntidad]'
UNION ALL 
SELECT '[dbo].[sp_ReporteDocumentosEmitidos]'

;


OPEN ProcedimientosCursor;
FETCH NEXT FROM ProcedimientosCursor INTO @Procedimiento;

WHILE @@FETCH_STATUS = 0
BEGIN   
    SET @Definicion = (
        SELECT OBJECT_DEFINITION(OBJECT_ID(@Procedimiento))
    );
    
    IF @Definicion IS NOT NULL
    BEGIN
        SET @NuevoScript = REPLACE(@Definicion, 'CREATE PROCEDURE', 'ALTER PROCEDURE');
        
        -- Reemplazar de "BANNER" a "DEVL"
        SET @NuevoScript = REPLACE(@NuevoScript, 'BANNER', 'DEVL');        
        
        BEGIN TRY
            EXEC sp_executesql @NuevoScript;
        END TRY
        BEGIN CATCH
            PRINT 'Error al modificar el procedimiento: ' + @Procedimiento;
            PRINT ERROR_MESSAGE();
        END CATCH;
    END
    ELSE
    BEGIN
        PRINT 'No se encontró la definición para el procedimiento: ' + @Procedimiento;
    END;

    FETCH NEXT FROM ProcedimientosCursor INTO @Procedimiento;
END

CLOSE ProcedimientosCursor;
DEALLOCATE ProcedimientosCursor;

GO
-- ***************************************************
USE BDUCCI;
GO

DECLARE @Procedimiento NVARCHAR(MAX);
DECLARE @Definicion NVARCHAR(MAX);
DECLARE @NuevoScript NVARCHAR(MAX);
DECLARE @CreateIndex INT;

DECLARE ProcedimientosCursor CURSOR FOR
SELECT QUOTENAME(ROUTINE_SCHEMA) + '.' + QUOTENAME(ROUTINE_NAME)
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE'
  AND (ROUTINE_SCHEMA = 'BANNER' OR ROUTINE_SCHEMA = 'dbo')
  AND 
	(
		ROUTINE_NAME LIKE '%sp_GetAllPrograms'
		OR ROUTINE_NAME LIKE '%FinalReportAp'
	);

OPEN ProcedimientosCursor;
FETCH NEXT FROM ProcedimientosCursor INTO @Procedimiento;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @Definicion = (
        SELECT OBJECT_DEFINITION(OBJECT_ID(@Procedimiento))
    );

    IF @Definicion IS NOT NULL
    BEGIN
        -- Buscar la posición real de 'CREATE PROCEDURE' o 'CREATE PROC'
        SET @CreateIndex = PATINDEX('%CREATE PROCEDURE%', UPPER(@Definicion));
        IF @CreateIndex = 0
            SET @CreateIndex = PATINDEX('%CREATE PROC%', UPPER(@Definicion));

        -- Si se encontró, reemplazar solo esa parte por ALTER PROCEDURE
        IF @CreateIndex > 0
        BEGIN
            DECLARE @AfterCreate NVARCHAR(MAX) = 
								CASE 
										WHEN UPPER(SUBSTRING(@Definicion, @CreateIndex, 16)) = 'CREATE PROCEDURE'
												THEN STUFF(@Definicion, @CreateIndex, 16, 'ALTER PROCEDURE')
										ELSE STUFF(@Definicion, @CreateIndex, 12, 'ALTER PROCEDURE')
								END;
						SET @Definicion = @AfterCreate;
        END

        -- Solo reemplazos de linked server
        SET @NuevoScript = REPLACE(@Definicion, 'OPENQUERY(BANNER', 'OPENQUERY(DEVL');
        SET @NuevoScript = REPLACE(@NuevoScript, '''BANNER''', '''DEVL''');

        -- Resultado
        -- PRINT '--- ALTERANDO SP: ' + @Procedimiento;
        PRINT @NuevoScript;
        EXEC sp_executesql @NuevoScript; -- Descomenta esta línea para ejecutar
    END
    ELSE
    BEGIN
        PRINT 'No se encontró la definición para el procedimiento: ' + @Procedimiento;
    END;

    FETCH NEXT FROM ProcedimientosCursor INTO @Procedimiento;
END

CLOSE ProcedimientosCursor;
DEALLOCATE ProcedimientosCursor;
