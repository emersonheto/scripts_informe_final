USE [BDUCCI]
GO

/* ===================================================================================================================
NOMBRE		: [pgpt].[sp_ListSendingDocumentsByIdDocumentoFinalReportAp]
FECHA		: 03/06/2025
AUTOR		: Emerson Herrera (Waytech)
OBJETIVO	: Listar los programas de Certificaciones de Programas de Especialización AP 
			  con filtro de código de informe final.

=================================================================================================================== */
CREATE PROCEDURE [pgpt].[sp_ListSendingDocumentsByIdDocumentoFinalReportAp]

	@CodigoDocumentoFinalReportAp varchar(20),
    @tipoConstancia INT,
    @nPagina INT = 1
AS
SET NOCOUNT ON
BEGIN
	IF OBJECT_ID('tempdb..#DataMaster') IS NOT NULL DROP TABLE #DataMaster;
	IF OBJECT_ID('tempdb..#tempData') IS NOT NULL DROP TABLE #tempData;

    DECLARE @nomProgramBANNER NVARCHAR(200);
    DECLARE @data_ntotal INT = 0;
    DECLARE @data_npage INT = 0;
	DECLARE @test varchar(8000) = '';

    SELECT DISTINCT
        per.IDPersonaN AS pidm,
		ISNULL(estado.IDEscuela,se.IDEscuela) AS escuelaId,
        ISNULL(estado.IDPerAcad,sec.Ciclo) AS perAcad,
        lista.Codigo AS dni,
        lista.Apellidos_Nombres AS alumno,
		UPPER(sed.NombreSede) sede,
		CASE WHEN @tipoConstancia = 1 THEN 'EVENTO POSGRADO UC' ELSE UPPER(ISNULL(esc.Facultad,'POSGRADO')) END tipoEscuela,
		ISNULL(lista.Programa,sec.Nombre_Programa) AS escuela,
		CASE WHEN @tipoConstancia IN (1,2) THEN 1 ELSE 3 END apto,
        ISNULL(gendoc.estado, 0) AS estado,
        ISNULL(gendoc.archivo, '/') AS archivo,
				ISNULL(sec.Fecha_inicio, se.FecInic) AS fecini,
        ISNULL(sec.Fecha_fin, se.FecFin) AS fecfin,
        @test AS asignaturas,
        ISNULL(lista.Correo_Personal, ISNULL(per.Email1,'sincorreo')) AS correo,
        lista.Seccion AS seccion,
        @tipoConstancia AS tipoconstancia,
        0 AS horas,
        ISNULL(gendoc.codigoFormato, '') AS codigoFormato,
        esc.IDTipoEsc AS IdTipoEsc,
		esc.IDFacultad AS IDFacultad 
		
    INTO #DataMaster
    FROM dbo.tblInfFinalDatosdelosEstudiantes lista
	INNER JOIN [dbo].[tblDocumentoFinalReportAp] drf ON lista.IdDocumentoFinalReportAp = drf.IdDocumentoFinalReportAp
    LEFT JOIN dbo.tblPersona per  ON lista.Codigo = per.DNI    
	LEFT JOIN BDUCCI.dbo.tblseccionC AS se ON se.IDSeccionC = lista.Seccion
	LEFT JOIN BDUCCI.dbo.tblAlumnoEstado estado ON per.DNI = estado.IDAlumno AND estado.IDSeccionC =se.IDSeccionC
	LEFT JOIN BDUCCI.dbo.tblSede sed ON estado.IDSede = sed.IDSede
	LEFT JOIN BDUCCI.dbo.tblEscuela AS esc ON esc.IDEscuela = se.IDEscuela AND esc.IDDependencia = 'UCCI'
	LEFT JOIN dbo.tblInfFinalSeccionCertificar sec  ON lista.Seccion = sec.Seccion AND sec.Nombre_Sede = sed.NombreSede 
	LEFT JOIN [pgpt].[tblGeneratedDocuments] gendoc ON 
    gendoc.id = (
        SELECT TOP 1 id
        FROM [pgpt].[tblGeneratedDocuments] gd
        WHERE gd.dni = lista.Codigo 
          AND gd.seccion = lista.Seccion 
          AND gd.tipoConstancia = @tipoConstancia
		  AND gd.estado in (1,2,3,4)
        ORDER BY version DESC
    ) 

	WHERE esc.IDTipoEsc IN ('ECO','POS') 
	AND drf.IdDocumentoFinalReportAp=  @CodigoDocumentoFinalReportAp;
	SELECT * INTO #tempData  FROM #DataMaster

    DECLARE @c INT = (SELECT COUNT(*) FROM #tempData)

    WHILE @c > 0
    BEGIN
        DECLARE @pidm VARCHAR(10);
        DECLARE @email VARCHAR(200);
        DECLARE @cursos NVARCHAR(4000);
        DECLARE @hours INT = 0;
        DECLARE @aprobado INT = 0;
        DECLARE @programa_codigo VARCHAR(10);
        DECLARE @perSeccion VARCHAR(10);
        DECLARE @seccion VARCHAR(20);
        DECLARE @startDate DATETIME;
        DECLARE @endDate DATETIME;
        DECLARE @listaEstudiantes VARCHAR(8000);
        DECLARE @idEscuela VARCHAR(10);
        DECLARE @idTipoEsc VARCHAR(10);
        DECLARE @idFacultad VARCHAR(10);
        DECLARE @seccionCorresponde BIT = 0;

        SELECT TOP 1 
            @pidm = pidm, 
            @programa_codigo = escuelaId,
            @perSeccion = perAcad,
            @seccion = seccion,
			@idEscuela = escuelaId,
			@idTipoEsc = IDTipoEsc,
			@idFacultad = IDFacultad,
			@nomProgramBANNER = escuela,
			@startDate = fecini,
			@endDate = fecfin
        FROM #tempData;
		 
		IF EXISTS (SELECT 1 WHERE @seccion IS NOT NULL AND @idTipoEsc IS NOT NULL AND @idEscuela  IS NOT NULL AND  @idFacultad  IS NOT NULL )
        BEGIN
            IF (@tipoConstancia = 1 AND @idEscuela IN ('coe','euc','evc','evt','ebi', 'EAR'))
                SET @seccionCorresponde = 1;
            ELSE IF (@tipoConstancia = 2 AND @idTipoEsc = 'POS' AND @idEscuela NOT IN ('coe','euc','evc','evt','ebi'))
                SET @seccionCorresponde = 1;
            ELSE IF (@tipoConstancia = 3 AND @idEscuela = 'CCP')
                SET @seccionCorresponde = 1;
            ELSE IF (@tipoConstancia = 4 AND @idTipoEsc = 'POS' AND @idEscuela != 'CCP' AND @idFacultad != 'MAE') --
                SET @seccionCorresponde = 1;
			ELSE IF (@tipoConstancia = 6 AND @idTipoEsc = 'POS' AND @idEscuela != 'CCP' AND @idFacultad != 'MAE')
                SET @seccionCorresponde = 1;
            ELSE
                SET @seccionCorresponde = 0;
        END
        
        IF @seccionCorresponde = 0
		BEGIN
			UPDATE #DataMaster
			SET 
				escuelaId = '0',  perAcad = '0',        dni = '0',        alumno = '0',        sede = '0',        tipoEscuela = '0',        escuela = '0',
				apto = 0,        estado = 0,        archivo = '0',        fecini = GETDATE(),        fecfin = GETDATE(),        asignaturas = '0',
				correo = '0',        seccion = '0',        tipoconstancia = 0,        horas = 0,        codigoFormato = '0'
			WHERE pidm = @pidm;
		END 

        IF(@tipoConstancia IN(1,2))
			BEGIN
				SET @aprobado = 1
			END
		ELSE IF (@tipoConstancia IN (3, 4, 6))
        BEGIN
            DECLARE @desaprob INT = 0;
			-- OBTENEMOS SI APROBO O NO EL PROGRAMA SET @desaprob
            EXECUTE('BEGIN BANINST1.SZKPIPB.p_count_failed_programs(?,?,?); END;', @programa_codigo, @pidm, @desaprob OUTPUT) AT BANNER;
            IF(@desaprob=0) SET @aprobado = 1;
        END

        IF(@aprobado = 1)
        BEGIN
		-- OBTENEMOS LA CANTIDAD DE HORAS SET @hours
            EXECUTE('BEGIN BANINST1.SZKPIPB.p_count_hours_programs(?,?,?); END;', @programa_codigo, @pidm, @hours OUTPUT) AT BANNER;
        END

		--OBTENEMOS LOS CURSOS QUE SE DIERON 1
		IF(@tipoConstancia IN(3,4,6) AND @aprobado = 1)
					BEGIN
						EXECUTE('BEGIN BANINST1.SZKPIPB.p_list_programs_epg(?,?,?,?); END;',@perSeccion,@idEscuela,@pidm,@cursos OUTPUT) AT BANNER
					SET @cursos =REPLACE(@cursos ,'?','Ñ')
					END
        IF(@tipoConstancia = 1 AND @aprobado = 1)
        BEGIN --OBTENEMOS LOS CURSOS QUE SE DIERON 2
            EXECUTE('BEGIN BANINST1.SZKPIPB.p_webinar_name_by_blck(?,?); END;', @seccion, @cursos OUTPUT) AT BANNER;
            SET @cursos = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@cursos,'|A','Á'),'|E','É'),'|I','Í'),'|O','Ó'),'|U','Ú');
        END
		/* Validando pagos para Secciones abiertas */
		IF(@aprobado = 1 AND @tipoConstancia IN ( 4, 6 ))
		BEGIN
			IF EXISTS(
					SELECT 1
					FROM dbo.tblCtaCorriente cta
					LEFT JOIN dbo.tblpersona per 
						ON cta.IDAlumno = per.DNI
					WHERE per.IDPersonaN = @pidm 
						AND cta.IDSeccionC = @seccion 
						AND cta.Deuda>0)
			BEGIN
				SET @aprobado = 0 -- Se setea a 0 si es que tiene deuda
			END
		END	
		
        UPDATE #DataMaster
        SET apto = @aprobado
        WHERE pidm = @pidm;

		IF @cursos IS NOT NULL
		BEGIN
			UPDATE #DataMaster SET asignaturas = @cursos, horas = @hours WHERE pidm = @pidm
		END

        DELETE FROM #tempData WHERE pidm = @pidm;  
		PRINT 'Eliminando: ' + @pidm;
        SET @c = (SELECT COUNT(*) FROM #tempData);
    END 

		SELECT DISTINCT
		pidm,
		escuelaId,
		perAcad,
		dni,
		alumno,
		sede,
		tipoEscuela,
		escuela,
		apto,
		estado,
		archivo,
		fecini,
		fecfin,
		asignaturas,
		correo,
		seccion,
		tipoconstancia,
		horas,
		codigoFormato,
		IdTipoEsc,
		@data_ntotal AS totalRegistros,
		@data_npage AS totalPaginas
	FROM #DataMaster
	ORDER BY alumno;	 
END