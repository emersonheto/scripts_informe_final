USE [BDUCCI]
GO

/*====================================================================================================
NOMBRE	: dbo.sp_FinalReportAP
FECHA	: 03/06/2025
AUTOR	: Brus Paucar (Waytech)
OBJETIVO: muestra la lista de alumnos que pertenecen a un programa
====================================================================================================*/
ALTER PROCEDURE [dbo].[sp_FinalReportAp]
    @studentCode VARCHAR(9),
    @program VARCHAR(12)
AS
SET NOCOUNT ON
BEGIN
    BEGIN TRY
        DECLARE @QUERY2 NVARCHAR(2000);
        DECLARE @TS_QUERY VARCHAR(MAX);
        DECLARE @BDOracle VARCHAR(10) = 'BANNER';
        DECLARE @WHERE_CLAUSE NVARCHAR(1000) = '';
        
        SET @WHERE_CLAUSE = 'WHERE SUBSTR(AREA_CODE,4,1)<>''C''';

        IF @program IS NOT NULL
            SET @WHERE_CLAUSE += ' AND PROGRAM_CODE=''' + @program +'''';

        IF @studentCode IS NOT NULL
            SET @WHERE_CLAUSE += ' AND DNI=''' + @studentCode +'''';
        
        SET @QUERY2 = '
        SELECT * FROM (
            SELECT
                BLOQUE_MATRICULA AS "Seccion",
                (CASE WHEN SUBJ_CODE = ''PSDP'' THEN ''DIPLOMAS''
                      WHEN SUBJ_CODE = ''PSEV'' THEN ''EVENTOS''
                      WHEN SUBJ_CODE = ''PSMA'' THEN ''MAESTRIA''
                      WHEN SUBJ_CODE = ''PSPA'' THEN ''PASANTIA''
                      WHEN SUBJ_CODE = ''PSPE'' THEN ''PROGRAMAS DE ESPECIALIZACION''
                      WHEN SUBJ_CODE = ''PSCC'' THEN ''CURSO CERRADO''
                      WHEN SUBJ_CODE = ''PSCU'' THEN ''CURSO''
                      WHEN SUBJ_CODE = ''PSDI'' THEN ''DIPLOMADO''
                      WHEN SUBJ_CODE = ''PSDO'' THEN ''DOCTORADO'' END) AS "TipoPrograma",
                PROGRAM_DESC AS "Programa",
                NOMBRE_CURSO AS "Asignatura",
                ESTADO_ASIGNATURA AS "EstadoAsignatura",
                TERM_CTLG AS "Periodo",
                (CASE WHEN INSTR(DEPT_DESC,''SEMI'') > 0 THEN ''SEMIPRESENCIAL''
                      WHEN INSTR(DEPT_DESC,''VIRTUAL'') > 0 THEN ''VIRTUAL''
                      WHEN INSTR(DEPT_DESC,''PRESENCIAL'') > 0 THEN ''PRESENCIAL''
                      WHEN INSTR(DEPT_DESC,''DISTANCIA'') > 0 THEN ''A DISTANCIA'' END) AS "Modalidad",
                (CASE CAMP_CODE WHEN ''F01'' THEN ''AREQUIPA''
                                WHEN ''F03'' THEN ''CUSCO''
                                WHEN ''S01'' THEN ''HUANCAYO''
                                WHEN ''F02'' THEN ''LIMA'' END) AS "Sede",
                DNI AS "Codigo",
                NOMBRE AS "ApellidosNombres",
                PROGRAM_CODE AS "ProgramCode",
                FECHA_TERMINO_NRC,
                ROW_NUMBER() OVER(PARTITION BY ASIGNATURA ORDER BY FECHA_TERMINO_NRC DESC) as rn
            FROM BANINST1.SZVALDI ' + @WHERE_CLAUSE + '
        )
        WHERE rn = 1';
        
        CREATE TABLE #UltimosIntentos (
            Seccion VARCHAR(100), TipoPrograma VARCHAR(100), Programa VARCHAR(100),
            Asignatura VARCHAR(100), Periodo VARCHAR(100), Modalidad VARCHAR(100),
            Sede VARCHAR(100), Codigo VARCHAR(100), ApellidosNombres VARCHAR(200),
            ProgramCode VARCHAR(100), FECHA_TERMINO_NRC DATETIME, EstadoAsignatura VARCHAR(44)
        );

        SET @TS_QUERY = '
        INSERT INTO #UltimosIntentos (
            Seccion, TipoPrograma, Programa, Asignatura, EstadoAsignatura, Periodo, Modalidad,
            Sede, Codigo, ApellidosNombres, ProgramCode, FECHA_TERMINO_NRC
        )
        SELECT 
            Seccion, TipoPrograma, Programa, Asignatura, EstadoAsignatura, Periodo, Modalidad,
            Sede, Codigo, ApellidosNombres, ProgramCode, FECHA_TERMINO_NRC
        FROM OPENQUERY(' + @BDOracle + ', ''' + REPLACE(@QUERY2, '''', '''''') + ''')';        
    
        EXEC (@TS_QUERY);
        
        DECLARE @Seccion VARCHAR(100), @TipoPrograma VARCHAR(100), @Programa VARCHAR(100),
                @Periodo VARCHAR(100), @Modalidad VARCHAR(100), @Sede VARCHAR(100),
                @ApellidosNombres VARCHAR(200), @ProgramCode VARCHAR(100);

        SELECT TOP 1
            @Seccion = Seccion, @TipoPrograma = TipoPrograma, @Programa = Programa,
            @Periodo = Periodo, @Modalidad = Modalidad, @Sede = Sede,
            @ApellidosNombres = ApellidosNombres, @ProgramCode = ProgramCode
        FROM #UltimosIntentos
        ORDER BY FECHA_TERMINO_NRC DESC;
                
        DECLARE @EstadoGlobal VARCHAR(20);

        SELECT @EstadoGlobal = CASE
            WHEN COUNT(CASE WHEN EstadoAsignatura = 'Desaprobado' THEN 1 END) > 0 THEN 'Desaprobado'
            WHEN COUNT(CASE WHEN EstadoAsignatura = 'Aprobado' THEN 1 END) = COUNT(*) THEN 'Aprobado'
            ELSE 'Desaprobado'
        END
        FROM #UltimosIntentos
        WHERE SUBSTRING(Seccion, 6, 2) = 'DM';
        
        SELECT 
            @studentCode AS "Codigo",
            @ApellidosNombres AS "ApellidosNombres",
            @TipoPrograma AS "TipoPrograma",
            @Programa AS "Programa",
            @Periodo AS "Periodo",
            @Modalidad AS "Modalidad",
            @Sede AS "Sede",
            @ProgramCode AS "ProgramCode",
            @EstadoGlobal AS "EstadoAsignatura";
        
        DROP TABLE #UltimosIntentos;

    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#UltimosIntentos') IS NOT NULL DROP TABLE #UltimosIntentos;
        SELECT 
            ERROR_NUMBER() AS ERROR_NUMBER,
            ERROR_MESSAGE() AS ERROR_MESSAGE
    END CATCH
END