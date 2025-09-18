USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [BANNER].[sp_AddInfFinalResultadoParticipantes2FinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Guarda el resumen por tipo de alumno
NRO		    FECHA		USUARIO					    MODIFICACION
1           17/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el último intento
====================================================================================================*/

ALTER PROCEDURE [BANNER].[sp_AddInfFinalResultadoParticipantes2FinalReportAp]
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

        IF(@p_Accion=1)
        BEGIN
            DECLARE @BDOracle VARCHAR(10)='BANNER';

            -- Crear tabla temporal sin índice
            CREATE TABLE #RESULTADO ( 
                Estado VARCHAR(20),
                IDAlumno INT,
                Seccion VARCHAR(50),
                Programa VARCHAR(100)
            )

            -- Consulta para Tipo_Reporte = 4 (usando @ProgramCode)
            DECLARE @OracleQuery4 NVARCHAR(MAX) = N'
            WITH EstadosPorArea AS (
                SELECT 
                    A.PIDM,
                    A.AREA_CODE,
										A.PROGRAM_DESC,
                    SUM(CASE 
                        WHEN A.ESTADO_ASIGNATURA = ''Aprobado'' 
                             AND A.PORCENT_INASISTENCIA <= 20 
                        THEN 1 ELSE 0 
                    END) AS CursosAprobados,
                    B.CANTCURSOS_MALLA,
                    MAX(A.STUDYPATH_STATUS_DESC) AS STUDYPATH_STATUS_DESC,
                    CASE 
                        WHEN SUM(CASE 
                                    WHEN A.ESTADO_ASIGNATURA = ''Aprobado'' 
                                         AND A.PORCENT_INASISTENCIA <= 20 
                                    THEN 1 ELSE 0 
                                 END) = B.CANTCURSOS_MALLA THEN ''APROBADO''
                        WHEN MAX(A.STUDYPATH_STATUS_DESC) <> ''Activo'' THEN MAX(A.STUDYPATH_STATUS_DESC)
                        ELSE ''DESAPROBADO''
                    END AS ESTADO_AREA
                FROM BANINST1.SZVALDI A
                INNER JOIN (
                    SELECT TERM_CODE_EFF, PROGRAM, MODALIDAD, AREA_CODE, COUNT(KEY_RULE) AS CANTCURSOS_MALLA
                    FROM BANINST1.SZVMALLA
                    GROUP BY TERM_CODE_EFF, PROGRAM, MODALIDAD, AREA_CODE
                ) B ON B.TERM_CODE_EFF = A.VERSION_PLAN
                    AND B.PROGRAM = A.PROGRAM_CODE
                    AND B.MODALIDAD = A.DEPT_CODE
                    AND B.AREA_CODE = A.AREA_CODE
                WHERE A.DNI IN (' + @StudentList + ')
                    AND SUBSTR(A.AREA_CODE,4,1) <> ''C''
                    AND A.PROGRAM_CODE = ''' + @ProgramCode + '''
                GROUP BY A.PIDM, A.AREA_CODE,A.PROGRAM_DESC, B.CANTCURSOS_MALLA
            )
            SELECT 
                PIDM,
                '''' AS SECCION,
                PROGRAM_DESC AS PROGRAMA,
                CASE 
                    WHEN COUNT(CASE WHEN ESTADO_AREA = ''DESAPROBADO'' THEN 1 END) > 0 THEN ''DESAPROBADO''
                    WHEN COUNT(CASE WHEN ESTADO_AREA != ''APROBADO'' THEN 1 END) > 0 THEN MAX(ESTADO_AREA)
                    ELSE ''APROBADO''
                END AS Estado_Academico
            FROM EstadosPorArea
            GROUP BY PIDM, PROGRAM_DESC '
            
            -- Consulta para Tipo_Reporte = 5 (usando @ProgramCode y @p_Area)
            DECLARE @OracleQuery5 NVARCHAR(MAX) = N'
            WITH T_CURSOSAPROBADOS AS (
                SELECT A.PIDM, A.STUDYPATH_STATUS_DESC, A.VERSION_PLAN, A.DEPT_CODE, MAX(A.BLOQUE_MATRICULA) AS SECCION, A.PROGRAM_DESC AS PROGRAMA,
                        SUM(CASE WHEN A.ESTADO_ASIGNATURA=''Aprobado'' AND A.PORCENT_INASISTENCIA<=20 THEN 1 
                            ELSE 0 END) AS CursosAprobados
                    FROM BANINST1.SZVALDI A
                    INNER JOIN BANINST1.SZVMALLA B 
                        ON B.PROGRAM=A.PROGRAM_CODE 
                        AND B.TERM_CODE_EFF=A.VERSION_PLAN 
                        AND B.KEY_RULE=A.ASIGNATURA 
                        AND B.AREA_CODE=A.AREA_CODE 
                        AND B.AREA_CODE=''' + @p_Area + '''
                    WHERE A.DNI IN (' + @StudentList + ')
                        --AND A.PROGRAM_CODE = ''' + @ProgramCode + '''
                        
                    GROUP BY A.PIDM, A.STUDYPATH_STATUS_DESC, A.VERSION_PLAN, A.DEPT_CODE, A.PROGRAM_DESC)

            SELECT (CASE WHEN A.CURSOSAPROBADOS>=B.CANTCURSOS THEN ''APROBADO'' 
                        ELSE (CASE WHEN A.STUDYPATH_STATUS_DESC<>''Activo'' THEN A.STUDYPATH_STATUS_DESC 
                        ELSE ''DESAPROBADO'' END) END) AS ESTADO_ACADEMICO,
                    A.PIDM,
                    A.SECCION,
                    A.PROGRAMA
                FROM T_CURSOSAPROBADOS A
                INNER JOIN (
                            SELECT TERM_CODE_EFF, ''' + @ProgramCode + ''' AS PROGRAM, COUNT(KEY_RULE) AS CANTCURSOS
                                FROM BANINST1.SZVMALLA
                                --WHERE PROGRAM = ''' + @ProgramCode + '''
                                WHERE AREA_CODE=''' + @p_Area + '''
                                GROUP BY TERM_CODE_EFF) B 
                    ON B.TERM_CODE_EFF=A.VERSION_PLAN'

            -- Consultas dinámicas completas con INSERT
            DECLARE @QUERY4 NVARCHAR(MAX) = N'
            INSERT INTO #RESULTADO (Estado, IDAlumno, Seccion, Programa)
            SELECT Estado_Academico, PIDM, SECCION, PROGRAMA 
            FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery4, '''', '''''') + ''')'
            
            DECLARE @QUERY5 NVARCHAR(MAX) = N'
            INSERT INTO #RESULTADO (Estado, IDAlumno, Seccion, Programa)
            SELECT ESTADO_ACADEMICO, PIDM, SECCION, PROGRAMA 
            FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery5, '''', '''''') + ''')'

            IF(@p_Tipo_Reporte=4)
            BEGIN
                EXEC sp_executesql @QUERY4;
            
                INSERT INTO [dbo].[tblinfFinalResultadoParticipantes2FinalReportAp] (
                    Seccion, Estado, Nro_Estudiantes, Fecha_Registro, 
                    Fecha_Edicion, Tipo_Reporte, Usuario_Creacion, Area,
                    Programa, Programa_Codigo, IdDocumentoFinalReportAp
                )
                SELECT
                    SECCION AS Seccion,
                    Estado AS Estado,
                    COUNT(IDAlumno) AS Nro_Estudiantes,
                    GETDATE() AS Fecha_Registro,
                    NULL AS Fecha_Edicion,
                    @p_Tipo_Reporte AS Tipo_Reporte,
                    @p_user_creacion AS Usuario_Creacion,
                    @p_Area AS Area,
                    Programa AS Programa,
                    @ProgramCode AS Programa_Codigo,
                    @p_IdDocumentoFinalReportAp AS IdDocumentoFinalReportAp
                FROM #RESULTADO 
                GROUP BY Estado, Programa, Seccion;

                DROP TABLE #RESULTADO;

                SELECT 0 AS 'NRO_RESPUESTA',
                    'SE INSERTÓ CORRECTAMENTE EL RESULTADO DE LOS PARTICIPANTES 2' AS 'MSG';
            END
            ELSE IF(@p_Tipo_Reporte=5)
            BEGIN
                EXEC sp_executesql @QUERY5;
            
                INSERT INTO [dbo].[tblinfFinalResultadoParticipantes2FinalReportAp] (
                    Seccion, Estado, Nro_Estudiantes, Fecha_Registro, 
                    Fecha_Edicion, Tipo_Reporte, Usuario_Creacion, Area,
                    Programa, Programa_Codigo, IdDocumentoFinalReportAp
                )
                SELECT
                    SECCION AS 'Seccion',
                    Estado AS 'Estado',
                    COUNT(IDAlumno) AS 'Nro_Estudiantes',
                    GETDATE() AS 'Fecha_Registro',
                    NULL AS 'Fecha_Edicion',
                    @p_Tipo_Reporte AS 'Tipo_Reporte',
                    @p_user_creacion AS 'Usuario_Creacion',
                    @p_Area AS 'Area',
                    PROGRAMA AS 'Programa',
                    @ProgramCode AS 'Programa_Codigo',
                    @p_IdDocumentoFinalReportAp AS 'IdDocumentoFinalReportAp'
                FROM #RESULTADO 
                GROUP BY SECCION, Estado, PROGRAMA;

                DROP TABLE #RESULTADO;

                SELECT 0 AS 'NRO_RESPUESTA',
                    'SE INSERTÓ CORRECTAMENTE EL RESULTADO DE LOS PARTICIPANTES 2' AS 'MSG';
            END
        END
        ELSE IF(@p_Accion=2)
        BEGIN
            DELETE FROM [dbo].[tblinfFinalResultadoParticipantes2FinalReportAp] 
            WHERE IdDocumentoFinalReportAp=@p_IdDocumentoFinalReportAp
            
            SELECT 0 AS 'NRO_RESPUESTA',
                'SE ELIMINÓ CORRECTAMENTE EL RESULTADO DE LOS PARTICIPANTES 2' AS 'MSG';
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
        SELECT @ErrorMessage AS status
    END CATCH
END