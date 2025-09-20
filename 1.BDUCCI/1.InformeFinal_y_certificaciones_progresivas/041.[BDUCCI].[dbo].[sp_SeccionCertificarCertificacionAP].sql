USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: [dbo].[sp_SeccionCertificarCertificacionAp]
FECHA	: 03/06/2025
AUTOR	: Emerson Herrera (Waytech)
OBJETIVO: Obtiene información necesaria para el archivo de informe final

MODIFICACIONES:
NRO		    FECHA		USUARIO					    MODIFICACIÓN
1           17/09/2025  Emerson Herrera(Waytech)	Se agrega funcionalidad para verificar el último intento y solo se tome en cuenta el id del codigo de reporte de informe final

====================================================================================================*/
ALTER PROCEDURE [dbo].[sp_SeccionCertificarCertificacionAp]
    @studentCode VARCHAR(12),
    @AreaCert VARCHAR(20)
AS
SET NOCOUNT ON
BEGIN
    BEGIN TRY
        DECLARE @BDOracle VARCHAR(10) = 'BANNER';
        DECLARE @OracleQuery NVARCHAR(MAX);
        DECLARE @FullQuery NVARCHAR(MAX);

        -- Tablas temporales para almacenar los datos de Oracle
        CREATE TABLE #MallaRequerida (Asignatura VARCHAR(20));
        CREATE TABLE #HistorialAlumno (
            Asignatura VARCHAR(20),
            EstadoAsignatura VARCHAR(30),
            PorcentajeInasistencia INT,
            TipoPrograma VARCHAR(50),
            Programa VARCHAR(200),
            Periodo VARCHAR(10),
            Modalidad VARCHAR(20),
            Sede VARCHAR(20),
            Codigo VARCHAR(12),
            ApellidosNombres VARCHAR(200),
            ProgramCode VARCHAR(10),
            FechaTerminoNRC DATE
        );
        CREATE TABLE #UltimosIntentos (
            Asignatura VARCHAR(20) PRIMARY KEY,
            EstadoAsignatura VARCHAR(30),
            PorcentajeInasistencia INT
        );

        SET @OracleQuery = N'SELECT KEY_RULE FROM BANINST1.SZVMALLA WHERE AREA_CODE = ''' + @AreaCert + '''';
        SET @FullQuery = N'SELECT KEY_RULE  FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')';
        
        INSERT INTO #MallaRequerida (Asignatura)
        EXEC sp_executesql @FullQuery;

        SET @OracleQuery = N'
            SELECT
                A.ASIGNATURA, A.ESTADO_ASIGNATURA, A.PORCENT_INASISTENCIA,
                (CASE WHEN A.SUBJ_CODE = ''PSDP'' THEN ''DIPLOMAS'' WHEN A.SUBJ_CODE = ''PSEV'' THEN ''EVENTOS'' WHEN A.SUBJ_CODE = ''PSMA'' THEN ''MAESTRIA'' WHEN A.SUBJ_CODE = ''PSPA'' THEN ''PASANTIA'' WHEN A.SUBJ_CODE = ''PSPE'' THEN ''PROGRAMAS DE ESPECIALIZACION'' WHEN A.SUBJ_CODE = ''PSCC'' THEN ''CURSO CERRADO'' WHEN A.SUBJ_CODE = ''PSCU'' THEN ''CURSO'' WHEN A.SUBJ_CODE = ''PSDI'' THEN ''DIPLOMADO'' WHEN A.SUBJ_CODE = ''PSDO'' THEN ''DOCTORADO'' END) AS TipoPrograma,
                B.AREA_DESC AS Programa,
                A.TERM_CTLG AS Periodo,
                (CASE WHEN INSTR(A.DEPT_DESC,''SEMI'') > 0 THEN ''SEMIPRESENCIAL'' WHEN INSTR(A.DEPT_DESC,''VIRTUAL'') > 0 THEN ''VIRTUAL'' WHEN INSTR(A.DEPT_DESC,''PRESENCIAL'') > 0 THEN ''PRESENCIAL'' WHEN INSTR(A.DEPT_DESC,''DISTANCIA'') > 0 THEN ''A DISTANCIA'' END) AS Modalidad,
                (CASE A.CAMP_CODE WHEN ''F01'' THEN ''AREQUIPA'' WHEN ''F03'' THEN ''CUSCO'' WHEN ''S01'' THEN ''HUANCAYO'' WHEN ''F02'' THEN ''LIMA'' END) AS SEDE,
                A.DNI AS Codigo, A.NOMBRE AS ApellidosNombres, A.PROGRAM_CODE AS ProgramCode,
                A.FECHA_TERMINO_NRC
            FROM BANINST1.SZVALDI A
            LEFT JOIN BANINST1.SZVMALLA B ON B.KEY_RULE = A.ASIGNATURA AND B.AREA_CODE = ''' + @AreaCert + '''
            WHERE A.DNI = ''' + @studentCode + '''';
        SET @FullQuery = N'SELECT ASIGNATURA,
                            ESTADO_ASIGNATURA,
                            PORCENT_INASISTENCIA,
                            TipoPrograma,
                            Programa,
                            Periodo,
                            Modalidad,
                            SEDE,
                            Codigo,
                            ApellidosNombres,
                            ProgramCode,
                            FECHA_TERMINO_NRC
                            FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')';
        
        INSERT INTO #HistorialAlumno
        EXEC sp_executesql @FullQuery;
        
        IF EXISTS (SELECT 1 FROM #HistorialAlumno WHERE Codigo IS NOT NULL)
        BEGIN            
            ;WITH RankedAttempts AS (
                SELECT 
                  Asignatura,
                  EstadoAsignatura,
                  PorcentajeInasistencia,
                  ROW_NUMBER() OVER(PARTITION BY Asignatura ORDER BY FechaTerminoNRC DESC) as rn
                FROM #HistorialAlumno
            )
            INSERT INTO #UltimosIntentos (Asignatura, EstadoAsignatura, PorcentajeInasistencia)
            SELECT Asignatura, EstadoAsignatura, PorcentajeInasistencia
            FROM RankedAttempts
            WHERE rn = 1;

            DECLARE @TotalRequerido INT, @TotalAprobados INT, @EstadoFinal VARCHAR(20);
            DECLARE @Programa VARCHAR(200);

            SELECT @TotalRequerido = COUNT(1) FROM #MallaRequerida;
            SELECT TOP 1 @Programa = Programa FROM #HistorialAlumno WHERE Programa IS NOT NULL;

            SELECT @TotalAprobados = COUNT(1)
            FROM #MallaRequerida malla
            INNER JOIN #UltimosIntentos intentos ON malla.Asignatura = intentos.Asignatura
            WHERE intentos.EstadoAsignatura = 'Aprobado' AND intentos.PorcentajeInasistencia <= 20;

            IF (@TotalRequerido > 0 AND @TotalAprobados = @TotalRequerido)
                SET @EstadoFinal = 'APROBADO';
            ELSE
                SET @EstadoFinal = 'DESAPROBADO';

            SELECT TOP 1
                TipoPrograma, @Programa AS Programa, @EstadoFinal AS EstadoAsignatura,
                Periodo, Modalidad, Sede, Codigo, ApellidosNombres, ProgramCode
            FROM #HistorialAlumno
            ORDER BY FechaTerminoNRC DESC;
        END
        ELSE
        BEGIN
            -- EL ALUMNO NO TIENE HISTORIAL, DEVOLVEMOS DESAPROBADO
            DECLARE @AreaDesc VARCHAR(200);
            SET @OracleQuery = N'SELECT AREA_DESC FROM BANINST1.SZVMALLA WHERE AREA_CODE = ''' + @AreaCert + ''' AND ROWNUM = 1';
            SET @FullQuery = N'SELECT AREA_DESC FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@OracleQuery, '''', '''''') + ''')';
            
            CREATE TABLE #AreaDescResult (DescResult VARCHAR(200));
            INSERT INTO #AreaDescResult EXEC sp_executesql @FullQuery;
            SELECT TOP 1 @AreaDesc = DescResult FROM #AreaDescResult;
            DROP TABLE #AreaDescResult;

            SELECT 
                NULL AS TipoPrograma, @AreaDesc AS Programa, 'DESAPROBADO' AS EstadoAsignatura,
                NULL AS Periodo, NULL AS Modalidad, NULL AS Sede, @studentCode AS Codigo,
                NULL AS ApellidosNombres, NULL AS ProgramCode;
        END
        
        IF OBJECT_ID('tempdb..#MallaRequerida') IS NOT NULL DROP TABLE #MallaRequerida;
        IF OBJECT_ID('tempdb..#HistorialAlumno') IS NOT NULL DROP TABLE #HistorialAlumno;
        IF OBJECT_ID('tempdb..#UltimosIntentos') IS NOT NULL DROP TABLE #UltimosIntentos;

    END TRY
    BEGIN CATCH        
        IF OBJECT_ID('tempdb..#MallaRequerida') IS NOT NULL DROP TABLE #MallaRequerida;
        IF OBJECT_ID('tempdb..#HistorialAlumno') IS NOT NULL DROP TABLE #HistorialAlumno;
        IF OBJECT_ID('tempdb..#UltimosIntentos') IS NOT NULL DROP TABLE #UltimosIntentos;

        SELECT 
            ERROR_NUMBER() AS ERROR_NUMBER,
            ERROR_MESSAGE() AS ERROR_MESSAGE;
    END CATCH
END