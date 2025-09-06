USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_CertificacionProgramaCertificacionAP]
FECHA	: 03/06/2025
AUTOR	: Emerson Herrera (Waytech)
OBJETIVO: Lista los alumnos que lograron la certificación en la sección de CP
====================================================================================================*/

ALTER PROCEDURE [BANNER].[sp_AddInfFinalCertificacionProgramaFinalReportAp] 
(
    @XmlStudents XML,
    @ProgramCode VARCHAR(3),
    @p_Area VARCHAR(20),
    @p_Tipo_Reporte INT,
    @p_user_creacion VARCHAR(200),
    @p_Accion INT,
    @p_IdDocumento VARCHAR(5),
    @p_IdDocumentoFinalReportAp VARCHAR(50)
)
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

        DECLARE @BDOracle VARCHAR(10)='BANNER';

        IF (@p_Accion=1)
        BEGIN
            -- Crear tabla temporal para resultados
            CREATE TABLE #RESULTADO ( 
                Codigo VARCHAR(100),
                Apellidos_Nombres VARCHAR(200),                
                Programa VARCHAR(100)
            )

            -- Consultas Oracle separadas para mejor legibilidad

            -- Consulta Oracle para Tipo_Reporte = 4 (VERSIÓN ORIGINAL RESTAURADA)
            DECLARE @OracleQuery4 NVARCHAR(MAX) = N'
            WITH T_RESUMEN AS ( 
                SELECT DNI, NOMBRE, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE,
                    SUM(CASE WHEN ESTADO_ASIGNATURA=''Aprobado'' AND PORCENT_INASISTENCIA<=20 THEN 1 
                        ELSE 0 END) AS CursosAprobados,
                    PROGRAM_DESC AS PROGRAMA
                FROM BANINST1.SZVALDI
                WHERE DNI IN (' + @StudentList + ')
                    AND PROGRAM_CODE = ''' + @ProgramCode + '''
                    
                    AND SUBSTR(AREA_CODE,4,1)<>''C''
                GROUP BY DNI, NOMBRE, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE,PROGRAM_DESC
                                
                                )

            SELECT DNI, NOMBRE,  PROGRAMA 
                FROM T_RESUMEN A
                INNER JOIN (
                    SELECT TERM_CODE_EFF, PROGRAM, MODALIDAD, COUNT(KEY_RULE) AS CANTCURSOS
                    FROM BANINST1.SZVMALLA
                    WHERE SUBSTR(AREA_CODE,4,1)<>''C''
                    GROUP BY TERM_CODE_EFF, PROGRAM, MODALIDAD) B 
                ON B.TERM_CODE_EFF=A.VERSION_PLAN 
                AND B.PROGRAM=A.PROGRAM_CODE 
                AND B.MODALIDAD=A.DEPT_CODE
                WHERE A.CURSOSAPROBADOS=B.CANTCURSOS'

            -- Consulta Oracle para Tipo_Reporte = 5 (NUEVA LÓGICA ROBUSTA APLICADA AQUÍ)
            DECLARE @OracleQuery5 NVARCHAR(MAX) = N'
            WITH T_ULTIMO_INTENTO AS (
            -- Paso 1: Aislamos el ÚLTIMO INTENTO de cada curso para cada alumno.
            SELECT
                A.DNI, A.NOMBRE, A.VERSION_PLAN, A.PROGRAM_CODE, A.DEPT_CODE,
                A.ESTADO_ASIGNATURA, A.PORCENT_INASISTENCIA, B.PROGRAM_DESC,
                ROW_NUMBER() OVER(PARTITION BY A.DNI, A.ASIGNATURA ORDER BY A.FECHA_TERMINO_NRC DESC) as orden_intento
            FROM BANINST1.SZVALDI A
            INNER JOIN BANINST1.SZVMALLA B
                ON B.PROGRAM = A.PROGRAM_CODE
                AND B.TERM_CODE_EFF = A.VERSION_PLAN
                AND B.KEY_RULE = A.ASIGNATURA
            WHERE
                B.AREA_CODE = '''''+ @p_Area + '''''
                AND A.DNI IN (' + @StudentList + ')
            ),
            T_RESUMEN_APROBADOS AS (
            -- Paso 2: Contamos los cursos aprobados del alumno, basándonos solo en su último intento.
            SELECT
                DNI, NOMBRE, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE, PROGRAM_DESC,
                SUM(CASE WHEN ESTADO_ASIGNATURA = ''''Aprobado'''' AND PORCENT_INASISTENCIA <= 20 THEN 1 ELSE 0 END) AS CursosAprobados
            FROM T_ULTIMO_INTENTO
            WHERE orden_intento = 1
            GROUP BY
                DNI, NOMBRE, VERSION_PLAN, PROGRAM_CODE, DEPT_CODE, PROGRAM_DESC
            ),
            T_TOTAL_CURSOS AS (
            -- Paso 3: Contamos el total de cursos requeridos por la malla para ese AreaCert.
            SELECT
                TERM_CODE_EFF, PROGRAM, MODALIDAD,
                COUNT(KEY_RULE) AS CANTCURSOS
            FROM BANINST1.SZVMALLA
            WHERE
                AREA_CODE = '''''+ @p_Area + '''''
            GROUP BY
                TERM_CODE_EFF, PROGRAM, MODALIDAD
            )
            -- Paso 4: Comparamos el total de aprobados del alumno (A) con el total requerido por la malla (B).
            SELECT
              A.DNI,
              A.NOMBRE,
              A.PROGRAM_DESC AS PROGRAMA
            FROM T_RESUMEN_APROBADOS A
            INNER JOIN T_TOTAL_CURSOS B
              ON B.TERM_CODE_EFF = A.VERSION_PLAN
              AND B.PROGRAM = A.PROGRAM_CODE
              AND B.MODALIDAD = A.DEPT_CODE
            WHERE
              A.CursosAprobados = B.CANTCURSOS' -- <<-- AQUÍ FALTABA LA COMILLA DE CIERRE

            -- Consultas dinámicas completas con INSERT
            DECLARE @QUERY4 NVARCHAR(MAX) = N'
            INSERT INTO #RESULTADO (Codigo, Apellidos_Nombres, Programa)
            SELECT DNI, NOMBRE, PROGRAMA 
            FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery4, '''', '''''') + ''')'
            
            DECLARE @QUERY5 NVARCHAR(MAX) = N'
            INSERT INTO #RESULTADO (Codigo, Apellidos_Nombres, Programa)
            SELECT DNI, NOMBRE, PROGRAMA 
            FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery5, '''', '''''') + ''')'

            IF(@p_Tipo_Reporte=4)
            BEGIN
                EXEC sp_executesql @QUERY4;
                
                INSERT INTO dbo.tblInfFinalCertificacionPrograma (seccion,
                        No, Codigo, Apellidos_Nombres, Fecha_Registro, 
                       Fecha_Edicion, Tipo_Reporte, Usuario_Creacion, Area, Programa, Programa_Codigo, IdDocumentoFinalReportAp)
                SELECT
                    null,
                    STR(ROW_NUMBER() OVER (ORDER BY Apellidos_Nombres)) AS 'No',  
                    Codigo,
                    Apellidos_Nombres,
                    GETDATE() AS 'Fecha_Registro',
                    NULL AS 'Fecha_Edicion',
                    @p_Tipo_Reporte AS 'Tipo_Reporte',
                    @p_user_creacion AS 'Usuario_Creacion',
                    @p_Area AS 'Area',
                    Programa,
                    @ProgramCode,
                    @p_IdDocumentoFinalReportAp AS 'IdDocumentoFinalReportAp'
                FROM #RESULTADO 
                ORDER BY 3;

                DROP TABLE #RESULTADO;
        
                SELECT 0 AS 'NRO_RESPUESTA',
                           'SE INSERTO CORRECTAMENTE LOS PARTICIPANTES' AS 'MSG';
            END
            ELSE IF(@p_Tipo_Reporte=5)
            BEGIN
                EXEC sp_executesql @QUERY5;
                
                INSERT INTO dbo.tblInfFinalCertificacionPrograma (seccion,
                        No, Codigo, Apellidos_Nombres, Fecha_Registro, 
                       Fecha_Edicion, Tipo_Reporte, Usuario_Creacion, Area, Programa, Programa_Codigo, IdDocumentoFinalReportAp)
                SELECT
                    null,
                    STR(ROW_NUMBER() OVER (ORDER BY Apellidos_Nombres)) AS 'No',  
                    Codigo,
                    Apellidos_Nombres,
                    GETDATE() AS 'Fecha_Registro',
                    NULL AS 'Fecha_Edicion',
                    @p_Tipo_Reporte AS 'Tipo_Reporte',
                    @p_user_creacion AS 'Usuario_Creacion',
                    @p_Area AS 'Area',
                    Programa,
                    @ProgramCode,
                    @p_IdDocumentoFinalReportAp AS 'IdDocumentoFinalReportAp'
                FROM #RESULTADO 
                ORDER BY 3;

                DROP TABLE #RESULTADO;

                SELECT 0 AS 'NRO_RESPUESTA',
                           'SE INSERTO CORRECTAMENTE LOS PARTICIPANTES' AS 'MSG';
            END
        END
        ELSE IF(@p_Accion=2)                            
        BEGIN
            DELETE FROM [dbo].tblInfFinalCertificacionPrograma 
            -- WHERE Programa_Codigo = @ProgramCode 
            -- AND Tipo_Reporte = @p_Tipo_Reporte;
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