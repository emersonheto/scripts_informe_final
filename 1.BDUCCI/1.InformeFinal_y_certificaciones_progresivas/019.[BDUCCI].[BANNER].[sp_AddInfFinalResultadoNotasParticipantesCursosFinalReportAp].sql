USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [BANNER].[sp_AddInfFinalResultadoNotasParticipantesCursosFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Guarda la lista de cursos de los participantes
====================================================================================================*/

ALTER PROCEDURE [BANNER].[sp_AddInfFinalResultadoNotasParticipantesCursosFinalReportAp]
    @XmlStudents XML,
    @ProgramCode VARCHAR(3),
    @p_Area VARCHAR(20),
    @p_Tipo_Reporte INT,
    @p_user_creacion VARCHAR(200),
    @p_Accion INT,
    @p_IdDocumento VARCHAR(5),
    @p_IdDocumentoFinalReportAp VARCHAR(50)
AS 
SET NOCOUNT ON
BEGIN
    BEGIN TRY
    	SET @p_IdDocumentoFinalReportAp = (
			SELECT CONCAT(IdAnio, IdInforme, IdDocumento, IdPrograma, IdSede, FORMAT(NroCorrelativo + 1, 'TMP000'), REPLACE(@p_user_creacion, ' ', ''))
			FROM [dbo].[tblCodigoInformeFinal]
			WHERE IdDocumento = @p_IdDocumento
			  AND IdPrograma = @ProgramCode
		)
    
        -- Validación de parámetros más robusta
        IF @XmlStudents IS NULL OR @XmlStudents.exist('/Students[1]') = 0
        BEGIN
            RAISERROR('El parámetro @XmlStudents debe contener datos XML válidos con la estructura <Students><Student><StudentCode>valor</StudentCode></Student></Students>', 16, 1)
            RETURN
        END
        
        IF NULLIF(@ProgramCode, '') IS NULL
        BEGIN
            RAISERROR('El parámetro @ProgramCode es requerido', 16, 1)
            RETURN
        END

        -- Crear tabla temporal para los estudiantes con clave primaria
        DECLARE @Students TABLE (
            StudentCode VARCHAR(9)
        )

        -- Insertar datos del XML con validación
        INSERT INTO @Students (StudentCode)
        SELECT 
            Student.value('(StudentCode)[1]', 'VARCHAR(9)') AS StudentCode
        FROM @XmlStudents.nodes('/Students/Student') AS T(Student)
        WHERE Student.value('(StudentCode)[1]', 'VARCHAR(9)') IS NOT NULL;

        -- Verificar que se hayan procesado estudiantes
        IF NOT EXISTS (SELECT 1 FROM @Students)
        BEGIN
            RAISERROR('No se encontraron códigos de estudiante válidos en el XML proporcionado', 16, 1)
            RETURN
        END

        -- Construir lista de Students para Oracle (método compatible con versiones anteriores)
        DECLARE @StudentList NVARCHAR(MAX) = ''
        SELECT @StudentList = @StudentList + '''' + REPLACE(StudentCode, '''', '''''') + ''',' 
        FROM @Students
        
        IF LEN(@StudentList) > 0
            SET @StudentList = LEFT(@StudentList, LEN(@StudentList) - 1)

        DECLARE @BDOracle VARCHAR(10)='DEVL';
        
        IF (@p_Accion=1)
        BEGIN
            -- Crear tabla temporal para resultados
            CREATE TABLE #RESULTADO ( 
                Curso VARCHAR(200),
                Seccion VARCHAR(50),
                Programa VARCHAR(1000)
            )

            -- Consulta Oracle para Tipo_Reporte = 4
            DECLARE @OracleQuery4 NVARCHAR(MAX) = N'
            SELECT DISTINCT 
                A.SUBJ_CODE||A.CRSE_NUMB||'' - ''||A.NOMBRE_CURSO AS CURSO,
                NULL AS SECCION,
                A.PROGRAM_DESC AS PROGRAMA
            FROM BANINST1.SZVALDI A
            INNER JOIN BANINST1.SZVMALLA B 
                ON B.TERM_CODE_EFF=A.VERSION_PLAN 
                AND B.PROGRAM=A.PROGRAM_CODE 
                AND B.MODALIDAD=A.DEPT_CODE
            WHERE A.DNI IN (' + @StudentList + ')
                AND A.PROGRAM_CODE = ''' + @ProgramCode + '''
                
                AND SUBSTR(A.AREA_CODE,4,1)<>''C'''

            -- Consulta Oracle para Tipo_Reporte = 5
            DECLARE @OracleQuery5 NVARCHAR(MAX) = N'
            SELECT DISTINCT 
                A.SUBJ_CODE||A.CRSE_NUMB||'' - ''||A.NOMBRE_CURSO AS CURSO,
                A.BLOQUE_MATRICULA AS SECCION,
                A.PROGRAM_DESC AS PROGRAMA
            FROM BANINST1.SZVALDI A
            INNER JOIN BANINST1.SZVMALLA B 
                ON B.PROGRAM=A.PROGRAM_CODE 
                AND B.TERM_CODE_EFF=A.VERSION_PLAN 
                AND B.KEY_RULE=A.ASIGNATURA 
                AND B.AREA_CODE=''' + @p_Area + '''
            WHERE A.DNI IN (' + @StudentList + ')
                AND A.PROGRAM_CODE = ''' + @ProgramCode + '''
            ';

            -- Consultas dinámicas completas con INSERT
            DECLARE @QUERY4 NVARCHAR(MAX) = N'
            INSERT INTO #RESULTADO (Curso,Seccion , Programa)
            SELECT CURSO, SECCION, PROGRAMA 
            FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery4, '''', '''''') + ''')'
            
            DECLARE @QUERY5 NVARCHAR(MAX) = N'
            INSERT INTO #RESULTADO (Curso, Seccion, Programa)
            SELECT CURSO, SECCION, PROGRAMA 
            FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery5, '''', '''''') + ''')'

            IF(@p_Tipo_Reporte=4)
            BEGIN
                EXEC sp_executesql @QUERY4;

                INSERT INTO [dbo].[tblInfFinalResultadoNotasParticipantesCursos] (
                    Seccion, Curso, Fecha_Registro, Fecha_Edicion, 
                    Tipo_Reporte, Usuario_Creacion, Area, Programa, Programa_Codigo, IdDocumentoFinalReportAp
                )
                SELECT
                    NULL AS 'Seccion',
                    ISNULL(Curso,'') AS 'Curso',
                    GETDATE() AS 'Fecha_Registro',
                    NULL AS 'Fecha_Edicion',
                    @p_Tipo_Reporte AS 'Tipo_Reporte',
                    @p_user_creacion AS 'Usuario_Creacion',
                    @p_Area AS 'Area',
                    PROGRAMA AS 'Programa',
                    @ProgramCode AS 'Programa_Codigo',
                    @p_IdDocumentoFinalReportAp AS 'IdDocumentoFinalReportAp'
                FROM #RESULTADO 
                GROUP BY Curso, Programa;

                DROP TABLE #RESULTADO;

                SELECT 0 AS 'NRO_RESPUESTA',
                    'SE INSERTÓ CORRECTAMENTE RESULTADO DE NOTAS DE LOS PARTICIPANTES' AS 'MSG';
            END
            ELSE IF(@p_Tipo_Reporte=5)
            BEGIN
                EXEC sp_executesql @QUERY5;

                INSERT INTO [dbo].[tblInfFinalResultadoNotasParticipantesCursos] (
                    Seccion, Curso, Fecha_Registro, Fecha_Edicion, 
                    Tipo_Reporte, Usuario_Creacion, Area, Programa, Programa_Codigo, IdDocumentoFinalReportAp
                )
                SELECT
                    -- SECCION AS 'Seccion',
                    ISNULL(Curso,'') AS 'Curso',
                    GETDATE() AS 'Fecha_Registro',
                    NULL AS 'Fecha_Edicion',
                    @p_Tipo_Reporte AS 'Tipo_Reporte',
                    @p_user_creacion AS 'Usuario_Creacion',
                    @p_Area AS 'Area',
                    PROGRAMA AS 'Programa',
                    @ProgramCode AS 'Programa_Codigo',
                    @p_IdDocumentoFinalReportAp AS 'IdDocumentoFinalReportAp'
                FROM #RESULTADO 
                GROUP BY Curso, Seccion, Programa;

                DROP TABLE #RESULTADO;

                SELECT 0 AS 'NRO_RESPUESTA',
                    'SE INSERTÓ CORRECTAMENTE RESULTADO DE NOTAS DE LOS PARTICIPANTES' AS 'MSG';
            END        
        END
        ELSE IF(@p_Accion=2)
        BEGIN
            DELETE FROM [dbo].[tblInfFinalResultadoNotasParticipantesCursos] 
            WHERE Programa_Codigo = @ProgramCode 
            AND Tipo_Reporte = @p_Tipo_Reporte;
            
            SELECT 0 AS 'NRO_RESPUESTA',
                   'SE ELIMINÓ CORRECTAMENTE RESULTADO DE NOTAS DE LOS PARTICIPANTES' AS 'MSG';
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000),
                @ErrorSeverity INT,
                @ErrorState INT;
        SELECT @ErrorMessage = ERROR_MESSAGE(),
               @ErrorSeverity = ERROR_SEVERITY(),
               @ErrorState = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        SELECT @ErrorMessage AS status;
    END CATCH
END