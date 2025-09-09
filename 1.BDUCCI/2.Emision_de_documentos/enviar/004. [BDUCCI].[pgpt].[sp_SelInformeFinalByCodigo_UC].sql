USE [BDUCCI]
GO
/* ===================================================================================================================
NOMBRE		: [pgpt].[sp_SelInformeFinalByCodigo_UC]
FECHA		: 03/06/2025
AUTOR		: Emerson Herrera (Waytech)
OBJETIVO	: Listar las certificaciones progresivas de maestrias con el filtro código de informe final. 
MODIFICACIONES
NRO 	FECHA		USUARIO		    			MODIFICACION
01		08/09/2025  EmersonHerrera (waytech)   Se cambia negocio de secciones a codigo de informe final 
=================================================================================================================== */
ALTER PROCEDURE [pgpt].[sp_SelInformeFinalByCodigo_UC]
    @IdDocumentoFinalReportAp VARCHAR(50),
    @tipoConstancia INT
AS
BEGIN
    SET NOCOUNT ON;
    
    WITH CursosConHoras AS (
		-- Pre-calculo de cursos con sus horas para evitar subconsultas repetidas
		SELECT 
			rn.Codigo,
			pd.Asignaturas as Curso,
			rn.Nota,
			rn.Estado_Academico,
			pd.horas_lectivas,
			pd.fecha_inicio,
			pd.fecha_fin,
			ROW_NUMBER() OVER (PARTITION BY rn.Codigo, rn.Curso ORDER BY pd.fecha_inicio) as rn
		FROM [dbo].tblInfFinalResultadoNotasParticipantes rn
		INNER JOIN [dbo].tblInfFinalProgramacionDocente pd  
			ON rn.iddocumentofinalreportap = pd.iddocumentofinalreportap 
			AND rn.Curso LIKE '%' + pd.Asignaturas + '%'
			AND rn.seccion=pd.seccion
		WHERE rn.iddocumentofinalreportap = @IdDocumentoFinalReportAp
	) 
-- 	SELECT 
-- 	codigo,SUM(nota),SUM(horas_lectivas), MIN(fecha_inicio), MAX(fecha_fin), estado_academico 
-- 	from CursosConHoras 
-- 	where rn=1 and codigo='16676389'
-- 	GROUP BY CODIGO,estado_academico 
	 
	SELECT 
		per.IDPersonaN AS pidm,
		ISNULL(t.InternalId,0) InternalId,  -- luego se habilita 
		per.Nombres,
		per.Appat,
		per.ApMat,
		'LIMA' as Sede, 
		'apeM' AS TipoPrograma,  
		lista.Programa,
		lista.seccion as IDSeccionC,
		lista.Area AS CodigoArea,
		lista.Codigo AS IDAlumno,
		ISNULL(CONVERT(DATETIME, ax.fecha_inicio, 120), '') as fecini,
		ISNULL(CONVERT(DATETIME, ax.fecha_fin, 120), '') as fecfin,
		t.IdDocumentoGenerado AS IDDocumentoGenerado,
		gendoc.archivo AS Archivo,
		lista.Codigo AS CodigoEstudiante, 
    ISNULL(lista.nombre_constancia_certificado,'') AS NombreConstanciaCertificado,
		NULL AS Promedio,
		NULL AS NivelMerito,
		NULL AS PeriodoInicio,
    NULL AS PeriodoFin,
		ISNULL(ax.horas_totales,0) as HorasLectivas,
		CASE WHEN ax.Estado_Academico ='DESAPROBADO' THEN 'Desaprobado' ELSE '' END AS Motivo,
		--'' as Motivo,
		CASE WHEN t.InternalId IS NOT NULL THEN 1 ELSE 0 END AS EstadoDocGenerado,
		IIF(ax.Estado_Academico='DESAPROBADO',1,0) as Desaprobado,  -- luego invertir
		lista.IdDocumentoFinalReportAp,
		gendoc.version
		-- , ISNULL(ax.asignatura_xml, '') as asignaturas
		 
 
	FROM tblInfFinalDatosdelosEstudiantes lista  
	LEFT JOIN [dbo].tblInfFinalCertificacionPrograma listaAp 
		ON listaAp.CODIGO = lista.CODIGO 
		AND listaAp.iddocumentofinalreportap = @IdDocumentoFinalReportAp  	--		select * from 	select * from dbo.tblSede where   select * from  dbo.tblAlumnoEstado where IDAlumno='16676389' and IDSeccionC='24MGPDM315'
	INNER JOIN dbo.tblPersona per 
		ON lista.Codigo = per.DNI
	LEFT JOIN dbo.tblEscuela esc 
		ON esc.IDEscuela = lista.Programa_Codigo
	-- LEFT JOIN dbo.tblInfFinalSeccionCertificar sec  ON lista.Seccion = sec.Seccion AND sed.NombreSede = sec.Nombre_Sede   -- observar   select * from dbo.tblInfFinalSeccionCertificar where seccion=''
	LEFT JOIN [pgpt].[tblGeneratedDocuments] gendoc   -- select * from dbo.tblInfFinalSeccionCertificar where iddocumentofinalreportap='25INFCPMGPAP034'
		ON gendoc.id = (
			SELECT TOP 1 id
			FROM [pgpt].[tblGeneratedDocuments] gd
			WHERE gd.dni = lista.Codigo 
				AND gd.seccion = lista.Seccion 
				AND gd.tipoConstancia = @tipoConstancia
				AND gd.iddocumentofinalreportap = lista.iddocumentofinalreportap
				AND gd.estado in (1,2,3,4)
			ORDER BY version DESC
		)
	LEFT JOIN pgpt.tblEmiConstancia_UC t ON t.IdDocumentoGenerado = gendoc.id AND t.iddocumentofinalreportap=lista.iddocumentofinalreportap  
	OUTER APPLY (
		SELECT 
			SUM(CAST(c.horas_lectivas AS INT)) as horas_totales,
			MIN(c.fecha_inicio) as fecha_inicio, 
			MAX(c.fecha_fin) as fecha_fin,
			c.Estado_Academico,
			CAST((
				SELECT 
					RTRIM(c2.Curso) as 'nombre',
					CAST(COALESCE(c2.Nota, '0') AS INT) as 'nota',
					CAST(c2.horas_lectivas AS INT) as 'horas'
					-- c2.Estado_Academico as 'estado'
				FROM CursosConHoras c2
				WHERE c2.Codigo = lista.Codigo 
					AND c2.rn = 1  -- Solo el primer registro por curso
				FOR XML PATH('curso'), ROOT('lista')
			) AS NVARCHAR(MAX)) as asignatura_xml
		FROM CursosConHoras c
		WHERE c.Codigo = lista.Codigo 
			AND c.rn = 1  -- Solo el primer registro por curso para evitar duplicados
		GROUP BY c.Estado_Academico
	) ax
	WHERE lista.iddocumentofinalreportap = @IdDocumentoFinalReportAp 
	AND lista.Tipo_Reporte=5   -- certificacion progresiva 
END;