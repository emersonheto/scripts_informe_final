USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [BANNER].[sp_AddInfFinalDatosAlumnoFinalReportAp]
FECHA	: 03/06/2025
AUTOR	: Alvaro Laveriano (Waytech)
OBJETIVO: Almacenar datos de alumnos matriculados para la aplicación Informe Final
====================================================================================================*/

CREATE PROCEDURE [BANNER].[sp_AddInfFinalDatosAlumnoFinalReportAp]
(
    @XmlStudents XML,
    @ProgramCode VARCHAR(3),
    @p_Area VARCHAR(20) = NULL,
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
            StudentCode VARCHAR(9) PRIMARY KEY
        )

        -- Insertar datos del XML con validación
        INSERT INTO @Students (StudentCode)
        SELECT DISTINCT
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
                Apellidos_Nombres VARCHAR(300),
                Telefono VARCHAR(200),
                Correo_Continental VARCHAR(200),
                Correo_Personal VARCHAR(200),
                Seccion VARCHAR(50),
                Programa VARCHAR(100),
                nombre_constancia_certificado VARCHAR(200)
            )

            -- Consultas Oracle separadas para mejor legibilidad

            -- Consulta Oracle para Tipo_Reporte = 4
            DECLARE @OracleQuery4 NVARCHAR(MAX) = N'
            SELECT A.DNI, A.NOMBRE, NVL(SPRTELE_PHONE_NUMBER,'' '') AS TELEFONO, 
                   A.DNI || ''@continental.edu.pe'' AS correo_continental,
                   B.GOREMAL_EMAIL_ADDRESS AS correo_personal,
                   MAX(A.BLOQUE_MATRICULA) AS SECCION,
                   A.PROGRAM_DESC AS PROGRAMA
                FROM BANINST1.SZVALDI A
                INNER JOIN GENERAL.GOREMAL B 
                    ON B.GOREMAL_PIDM=A.PIDM 
                    AND GOREMAL_EMAL_CODE=''EPER''
                INNER JOIN (
                        SELECT GOREMAL_PIDM, MAX(GOREMAL_SURROGATE_ID) AS GOREMALID
                            FROM GENERAL.GOREMAL
                            WHERE GOREMAL_EMAL_CODE=''EPER''
                            GROUP BY GOREMAL_PIDM
                            ) C 
                    ON C.GOREMAL_PIDM=B.GOREMAL_PIDM 
                    AND C.GOREMALID=B.GOREMAL_SURROGATE_ID
                LEFT JOIN SATURN.SPRTELE B 
                    ON B.SPRTELE_PIDM=A.PIDM 
                    AND SPRTELE_SEQNO=2
                WHERE A.DNI IN (' + @StudentList + ')
                    AND A.PROGRAM_CODE = ''' + @ProgramCode + '''
                    AND NVL(A.STUDYPATH_BLOQUE, '' '') = A.BLOQUE_MATRICULA
				GROUP BY 
			    	A.DNI, A.NOMBRE, NVL(B.SPRTELE_PHONE_NUMBER, '' ''), A.DNI || ''@continental.edu.pe'',
			    	B.GOREMAL_EMAIL_ADDRESS, A.PROGRAM_DESC
                ORDER BY A.NOMBRE'

            -- Consulta Oracle para Tipo_Reporte = 5
            DECLARE @OracleQuery5 NVARCHAR(MAX) = N'
            SELECT A.DNI, A.NOMBRE, NVL(SPRTELE_PHONE_NUMBER,'' '') AS TELEFONO, 
                   A.DNI || ''@continental.edu.pe'' AS correo_continental,
                   E.GOREMAL_EMAIL_ADDRESS AS correo_personal,
                   MAX(A.BLOQUE_MATRICULA) AS SECCION,
                   A.PROGRAM_DESC AS PROGRAMA,
				   H.SMRALIB_DESCRIPTION AS nombre_constancia_certificado
                FROM BANINST1.SZVALDI A
                INNER JOIN BANINST1.SZVMALLA B
                    ON B.PROGRAM=A.PROGRAM_CODE 
                    AND B.TERM_CODE_EFF=A.VERSION_PLAN 
                    AND B.KEY_RULE=A.ASIGNATURA 
                    AND B.AREA_CODE=''' + @p_Area + '''
				LEFT JOIN SATURN.SMRALIB H ON H.SMRALIB_AREA=B.AREA_CODE
                LEFT JOIN (
                        SELECT C.GOREMAL_PIDM, C.GOREMAL_EMAIL_ADDRESS
                            FROM GENERAL.GOREMAL C
                            INNER JOIN (
                                    SELECT GOREMAL_PIDM, MAX(GOREMAL_SURROGATE_ID) AS GOREMALID
                                        FROM GENERAL.GOREMAL
                                        WHERE GOREMAL_EMAL_CODE=''EPER''
                                        GROUP BY GOREMAL_PIDM
                                        ) D 
                                ON D.GOREMAL_PIDM=C.GOREMAL_PIDM 
                                AND D.GOREMALID=C.GOREMAL_SURROGATE_ID
                            WHERE GOREMAL_EMAL_CODE=''EPER'') E 
                    ON E.GOREMAL_PIDM=A.PIDM
                LEFT JOIN SATURN.SPRTELE F 
                    ON F.SPRTELE_PIDM=A.PIDM 
                    AND F.SPRTELE_SEQNO=2
                WHERE A.DNI IN (' + @StudentList + ')
                    AND A.PROGRAM_CODE = ''' + @ProgramCode + '''
                    AND NVL(A.STUDYPATH_BLOQUE, '' '') = A.BLOQUE_MATRICULA
				GROUP BY 
			    	A.DNI, A.NOMBRE, NVL(SPRTELE_PHONE_NUMBER, '' ''), A.DNI || ''@continental.edu.pe'',
			    	E.GOREMAL_EMAIL_ADDRESS, A.PROGRAM_DESC, H.SMRALIB_DESCRIPTION'

            -- Consultas dinámicas completas con INSERT
            DECLARE @QUERY4 NVARCHAR(MAX) = N'
            INSERT INTO #RESULTADO (Codigo, Apellidos_Nombres, Telefono, Correo_Continental, Correo_Personal, Seccion, Programa)
            SELECT DNI, NOMBRE, TELEFONO, correo_continental, correo_personal, SECCION, PROGRAMA 
            FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery4, '''', '''''') + ''')'
                
                PRINT 'A'
            
            DECLARE @QUERY5 NVARCHAR(MAX) = N'
            INSERT INTO #RESULTADO (Codigo, Apellidos_Nombres, Telefono, Correo_Continental, Correo_Personal, Seccion, Programa, nombre_constancia_certificado)
            SELECT DNI, NOMBRE, TELEFONO, correo_continental, correo_personal, SECCION, PROGRAMA, nombre_constancia_certificado
            FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery5, '''', '''''') + ''')'

            IF(@p_Tipo_Reporte=4)
            BEGIN
                EXEC sp_executesql @QUERY4;
                
                INSERT INTO [dbo].[tblInfFinalDatosdelosEstudiantes] (
                    Seccion, No, Codigo, Apellidos_Nombres, Telefono, 
                    Correo_Continental, Correo_Personal, Fecha_Registro, 
                    Fecha_Edicion, Tipo_Reporte, Usuario_Creacion, Area, Programa, Programa_Codigo, IdDocumentoFinalReportAp)
                SELECT
                    Seccion,
                    STR(ROW_NUMBER() OVER (ORDER BY Apellidos_Nombres)) AS 'No',  
                    Codigo,
                    SUBSTRING(REPLACE(Apellidos_Nombres, ',', ''), 1, 100),
                    SUBSTRING(Telefono,1,20),
                    ISNULL(SUBSTRING(Correo_Continental,1,50),''),
                    ISNULL(SUBSTRING(Correo_Personal,1,50),''),
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
                    'SE INSERTÓ CORRECTAMENTE LOS PARTICIPANTES' AS 'MSG';
            END 
            ELSE IF(@p_Tipo_Reporte=5)
            BEGIN
                EXEC sp_executesql @QUERY5;
                
                INSERT INTO [dbo].[tblInfFinalDatosdelosEstudiantes] (
                    Seccion, No, Codigo, Apellidos_Nombres, Telefono, 
                    Correo_Continental, Correo_Personal, Fecha_Registro, 
                    Fecha_Edicion, Tipo_Reporte, Usuario_Creacion, Area, Programa, Programa_Codigo, nombre_constancia_certificado, IdDocumentoFinalReportAp)
                SELECT
                    Seccion,
                    STR(ROW_NUMBER() OVER (ORDER BY Apellidos_Nombres)) AS 'No',  
                    Codigo,
                    SUBSTRING(REPLACE(Apellidos_Nombres, ',', ''), 1, 100),
                    SUBSTRING(Telefono,1,20),
                    ISNULL(SUBSTRING(Correo_Continental,1,50),''),
                    ISNULL(SUBSTRING(Correo_Personal,1,50),''),
                    GETDATE() AS 'Fecha_Registro',
                    NULL AS 'Fecha_Edicion',
                    @p_Tipo_Reporte AS 'Tipo_Reporte',
                    @p_user_creacion AS 'Usuario_Creacion',
                    @p_Area AS 'Area',
                    Programa,
                    @ProgramCode,
                    nombre_constancia_certificado,
                    @p_IdDocumentoFinalReportAp AS 'IdDocumentoFinalReportAp'
                FROM #RESULTADO 
                ORDER BY 3;

                DROP TABLE #RESULTADO;
                
                SELECT 0 AS 'NRO_RESPUESTA',
                    'SE INSERTÓ CORRECTAMENTE LOS PARTICIPANTES' AS 'MSG';
            END            
        END
        ELSE IF(@p_Accion=2)
        BEGIN
            DELETE FROM [dbo].[tblInfFinalDatosdelosEstudiantes] 
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