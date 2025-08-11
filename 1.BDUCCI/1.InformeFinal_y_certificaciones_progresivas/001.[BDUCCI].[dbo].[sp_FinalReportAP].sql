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
   DECLARE @QUERY2 NVARCHAR(2000) 
   DECLARE @TS_QUERY VARCHAR(MAX)
   DECLARE @BDOracle VARCHAR(10)='BANNER'
   DECLARE @WHERE_CLAUSE NVARCHAR(1000) = ''

    -- Construye dinámicamente la cláusula WHERE
    SET @WHERE_CLAUSE = 'WHERE SUBSTR(AREA_CODE,4,1)<>''''C'''' AND SUBSTR(BLOQUE_MATRICULA, 6, 2) = ''''DM'''''

    IF @program IS NOT NULL
        SET @WHERE_CLAUSE += ' AND PROGRAM_CODE=''''' + @program +''''''

    IF @studentCode IS NOT NULL
        SET @WHERE_CLAUSE += ' AND DNI=''''' + @studentCode +''''''

   SET @QUERY2= '
   SELECT DISTINCT BLOQUE_MATRICULA AS "Seccion",
       (CASE WHEN SUBJ_CODE = ''''PSDP'''' THEN ''''DIPLOMAS''''
            WHEN SUBJ_CODE = ''''PSEV'''' THEN ''''EVENTOS''''
            WHEN SUBJ_CODE = ''''PSMA'''' THEN ''''MAESTRIA''''
            WHEN SUBJ_CODE = ''''PSPA'''' THEN ''''PASANTIA''''
            WHEN SUBJ_CODE = ''''PSPE'''' THEN ''''PROGRAMAS DE ESPECIALIZACION''''
            WHEN SUBJ_CODE = ''''PSCC'''' THEN ''''CURSO CERRADO''''
            WHEN SUBJ_CODE = ''''PSCU'''' THEN ''''CURSO''''
            WHEN SUBJ_CODE = ''''PSDI'''' THEN ''''DIPLOMADO''''
            WHEN SUBJ_CODE = ''''PSDO'''' THEN ''''DOCTORADO'''' END) AS "TipoPrograma",
       PROGRAM_DESC AS "Programa",
       NOMBRE_CURSO AS "Asignatura",
       ESTADO_ASIGNATURA AS "EstadoAsignatura",
       TERM_CTLG AS "Periodo",
       (CASE WHEN INSTR(DEPT_DESC,''''SEMI'''') > 0 THEN ''''SEMIPRESENCIAL''''
             WHEN INSTR(DEPT_DESC,''''VIRTUAL'''') > 0 THEN ''''VIRTUAL''''
             WHEN INSTR(DEPT_DESC,''''PRESENCIAL'''') > 0 THEN ''''PRESENCIAL''''
             WHEN INSTR(DEPT_DESC,''''DISTANCIA'''') > 0 THEN ''''A DISTANCIA'''' END) AS "Modalidad",
       (CASE CAMP_CODE WHEN ''''F01'''' THEN ''''AREQUIPA''''
                       WHEN ''''F03'''' THEN ''''CUSCO''''
                       WHEN ''''S01'''' THEN ''''HUANCAYO''''
                       WHEN ''''F02'''' THEN ''''LIMA'''' END) AS "Sede",
        DNI AS "Codigo",
        NOMBRE AS "ApellidosNombres",
        PROGRAM_CODE AS "ProgramCode",
        FECHA_TERMINO_NRC
   FROM BANINST1.SZVALDI ' + @WHERE_CLAUSE

   -- Crear tabla temporal para almacenar los resultados
   CREATE TABLE #TempResults (
       Seccion VARCHAR(100),
       TipoPrograma VARCHAR(100),
       Programa VARCHAR(100),
       Asignatura VARCHAR(100),
       Periodo VARCHAR(100),
       Modalidad VARCHAR(100),
       Sede VARCHAR(100),
       Codigo VARCHAR(100),
       ApellidosNombres VARCHAR(200),
       ProgramCode VARCHAR(100),
       FECHA_TERMINO_NRC DATETIME,
       EstadoAsignatura VARCHAR(44)
   )

   -- Insertar datos en la tabla temporal desde Oracle
   SET @TS_QUERY= '
   INSERT INTO #TempResults
   SELECT 
       Seccion, TipoPrograma, Programa, Asignatura, Periodo, 
       Modalidad, Sede, Codigo, ApellidosNombres, ProgramCode, FECHA_TERMINO_NRC, EstadoAsignatura
   FROM OPENQUERY('+@BDOracle+','''+@QUERY2+''')';
 
   EXEC (@TS_QUERY)

   -- Primero filtrar por 'DM' en Seccion
   SELECT 
       Seccion,
       TipoPrograma,
       Programa,
       Asignatura,
       Periodo,
       Modalidad,
       Sede,
       Codigo,
       ApellidosNombres,
       ProgramCode,
       FECHA_TERMINO_NRC,
       EstadoAsignatura
   INTO #FilteredResults
   FROM #TempResults ; 
   
   WITH EstadoConsolidado AS (
            SELECT 
                codigo,
                MAX(apellidosNombres) AS apellidosNombres,
                MAX(seccion) AS seccion,
                MAX(tipoPrograma) AS tipoPrograma,
                MAX(programa) AS programa,
                MAX(periodo) AS periodo,
                MAX(modalidad) AS modalidad,
                MAX(sede) AS sede,
                MAX(programCode) AS programCode,
                CASE 
                    WHEN COUNT(CASE WHEN estadoAsignatura = 'Desaprobado' THEN 1 END) > 0 THEN 'Desaprobado'
                    WHEN COUNT(CASE WHEN estadoAsignatura = 'Aprobado' THEN 1 END) = COUNT(*) THEN 'Aprobado'
                    ELSE 'Desaprobado' -- Para casos con NULLs o mezcla
                END AS estadoGlobal,
                MAX(fecha_termino_nrc) AS ultimaFecha
            FROM #FilteredResults
            GROUP BY codigo
        )
        SELECT 
            codigo AS "Codigo",
            seccion AS "Seccion",
            tipoPrograma AS "TipoPrograma",
            programa AS "Programa",
            '' AS "Asignatura", -- Asignatura vacía
            periodo AS "Periodo",
            modalidad AS "Modalidad",
            sede AS "Sede",
            apellidosNombres AS "ApellidosNombres",
            programCode AS "ProgramCode",
            estadoGlobal AS "EstadoAsignatura"
        FROM EstadoConsolidado
        ORDER BY codigo;

   -- Eliminar tablas temporales
   DROP TABLE #TempResults
   DROP TABLE #FilteredResults

END TRY
BEGIN CATCH
    SELECT 
     ERROR_NUMBER() AS ERROR_NUMBER,
     ERROR_MESSAGE() AS ERROR_MESSAGE
END CATCH
END