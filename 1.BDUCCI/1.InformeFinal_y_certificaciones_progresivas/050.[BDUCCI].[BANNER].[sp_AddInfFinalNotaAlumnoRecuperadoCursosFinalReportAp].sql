USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [BANNER].[sp_AddInfFinalNotaAlumnoRecuperadoCursosFinalReportAp]
FECHA	: 17/09/2025
AUTOR	: Emerson Herrera (Waytech)
OBJETIVO: Se agrega funcionalidad para verificar el último intento y solo se tome en cuenta el id del codigo de reporte de informe final
====================================================================================================*/

CREATE PROCEDURE [BANNER].[sp_AddInfFinalNotaAlumnoRecuperadoCursosFinalReportAp]
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
        
        DECLARE @Students TABLE (
            StudentCode VARCHAR(9)
        )
        
        INSERT INTO @Students (StudentCode)
        SELECT 
            Student.value('(StudentCode)[1]', 'VARCHAR(9)') AS StudentCode
        FROM @XmlStudents.nodes('/Students/Student') AS T(Student)
        WHERE Student.value('(StudentCode)[1]', 'VARCHAR(9)') IS NOT NULL;
        
        IF NOT EXISTS (SELECT 1 FROM @Students)
        BEGIN
            RAISERROR('No se encontraron códigos de estudiante válidos en el XML proporcionado', 16, 1)
            RETURN
        END
        
        DECLARE @StudentList NVARCHAR(MAX) = ''
        SELECT @StudentList = @StudentList + '''' + REPLACE(StudentCode, '''', '''''') + ''',' 
        FROM @Students
        
        IF LEN(@StudentList) > 0
            SET @StudentList = LEFT(@StudentList, LEN(@StudentList) - 1)

        DECLARE @BDOracle VARCHAR(10)='BANNER';
        
        IF (@p_Accion=1)
        BEGIN            
            CREATE TABLE #RESULTADO ( 
                Curso VARCHAR(200),
                Seccion VARCHAR(50),
                Programa VARCHAR(1000)
            )

            -- Consulta Oracle para Tipo_Reporte = 4
								
                DECLARE @OracleQuery4 NVARCHAR(MAX) = N'
                WITH cursos_recuperados AS (
                    SELECT 
                        A.DNI,
                        A.NOMBRE,
                        NVL(A.STUDYPATH_BLOQUE, A.BLOQUE_MATRICULA) AS STUDYPATH_BLOQUE,
                        NRC||'' - ''||NOMBRE_CURSO AS CURSO,     
                        NVL(A.GRDE_CODE,''0'') AS GRDE_CODE,
                        ''RECUPERADO'' AS ESTADO_RECUPERACION,
                        A.FECHA_INICIO_NRC,
                        A.ESTADO_ASIGNATURA,
                        A.PROGRAM_DESC AS PROGRAMA,
                        COUNT(A.NRC) OVER (PARTITION BY A.DNI, A.SUBJ_CODE, A.CRSE_NUMB) AS total_intentos,
                        ROW_NUMBER() OVER (
                                PARTITION BY A.DNI, A.SUBJ_CODE, A.CRSE_NUMB 
                                ORDER BY A.FECHA_INICIO_NRC DESC
                        ) AS numero_de_intento
                    FROM BANINST1.SZVALDI A
                    WHERE A.DNI IN (' + @StudentList + ')
                            AND A.PROGRAM_CODE = ''' + @ProgramCode + '''    
                            AND SUBSTR(A.AREA_CODE,4,1) <> ''C''
                    ORDER BY A.FECHA_INICIO_NRC ASC
                )
                SELECT DISTINCT
                        CURSO, 
                        STUDYPATH_BLOQUE AS SECCION,
                        PROGRAMA
                FROM cursos_recuperados
                WHERE total_intentos > 1 
                    AND numero_de_intento <= 2 
            ';

            -- Consulta Oracle para Tipo_Reporte = 5
            DECLARE @OracleQuery5 NVARCHAR(MAX) = N'
            SELECT DISTINCT 
                A.NRC||'' - ''||A.NOMBRE_CURSO AS CURSO,
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

                INSERT INTO [dbo].[tblInfFinalConsolidadoNotasEstudiantesRecuperadosCursos] (
                    Curso, Fecha_Registro, Fecha_Edicion, 
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
                GROUP BY Curso, Programa;

                DROP TABLE #RESULTADO;

                SELECT 0 AS 'NRO_RESPUESTA',
                    'SE INSERTÓ CORRECTAMENTE RESULTADO DE NOTAS DE LOS PARTICIPANTES' AS 'MSG';
            END
            ELSE IF(@p_Tipo_Reporte=5)
            BEGIN
                EXEC sp_executesql @QUERY5;

                INSERT INTO [dbo].[tblInfFinalConsolidadoNotasEstudiantesRecuperadosCursos] (
                    Seccion, Curso, Fecha_Registro, Fecha_Edicion, 
                    Tipo_Reporte, Usuario_Creacion, Area, Programa, Programa_Codigo, IdDocumentoFinalReportAp
                )
                SELECT
                    SECCION AS 'Seccion',
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
            DELETE FROM [dbo].[tblInfFinalConsolidadoNotasEstudiantesRecuperadosCursos]
            WHERE IdDocumentoFinalReportAp=@p_IdDocumentoFinalReportAp
            
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