USE [BDUCCI]
GO

/* ===================================================================================================================
NOMBRE		: [pgpt].[sp_ListSendingDocumentsByIdDocumentoFinalReportAp]
FECHA		: 03/06/2025
AUTOR		: Emerson Herrera (Waytech)
OBJETIVO	: Listar los programas de Certificaciones de Programas de Especializaci�n AP 
			  con filtro de c�digo de informe final.
MODIFICACIONES
NRO 	FECHA		USUARIO		    			MODIFICACION
01		22/09/2025  EmersonHerrera (waytech)   Se cambia negocio de secciones a codigo de informe final 
=================================================================================================================== */
ALTER PROCEDURE [pgpt].[sp_ListSendingDocumentsByIdDocumentoFinalReportAp]

	@CodigoDocumentoFinalReportAp varchar(60),
    @tipoConstancia INT,
    @numeroPagina INT = 1
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
			AND CASE 
                WHEN CHARINDEX(' - ', rn.Curso) > 0 
                THEN SUBSTRING(rn.Curso, CHARINDEX(' - ', rn.Curso) + 3, LEN(rn.Curso))
                ELSE rn.Curso
            END = pd.Asignaturas
			AND rn.seccion=pd.seccion
		WHERE rn.iddocumentofinalreportap = @CodigoDocumentoFinalReportAp
	)
	SELECT 
		per.IDPersonaN AS pidm,
		lista.Programa_Codigo as escuelaId,
		'' as perAcad,
		lista.Codigo as dni,
		REPLACE(lista.Apellidos_Nombres, ',', '') as alumno,
		'LIMA' as sede, 
		UPPER(ISNULL(esc.Facultad,'POSGRADO')) as tipoEscuela, 
		ISNULL(lista.Programa,esc.Nombre) AS escuela,  
		IIF(ax.Estado_Academico='DESAPROBADO',0,1) as apto,
		ISNULL(gendoc.estado, 0) as estado,
		ISNULL(gendoc.archivo, '/') AS archivo,
		ISNULL(CONVERT(DATETIME, ax.fecha_inicio, 120), '') as fecini,
		ISNULL(CONVERT(DATETIME, ax.fecha_fin, 120), '') as fecfin,
		ISNULL(ax.asignatura_xml, '') as asignaturas,
		ISNULL(lista.Correo_Personal, '') as correo,
		ISNULL(lista.Seccion,'') as seccion,
		@tipoConstancia as tipoconstancia, 
		ISNULL(ax.horas_totales,0) as horas,
		ISNULL(gendoc.codigoFormato,'') AS codigoFormato,
		ISNULL(esc.IDTipoEsc, '') AS IdTipoEsc,
		0 AS totalRegistros,
		0 AS totalPaginas
		,		lista.IdDocumentoFinalReportAp
		
	FROM [dbo].tblInfFinalDatosdelosEstudiantes lista
	INNER JOIN dbo.tblPersona per 
		ON lista.Codigo = per.DNI
	LEFT JOIN dbo.tblEscuela esc 
		ON esc.IDEscuela = lista.Programa_Codigo
	LEFT JOIN [pgpt].[tblGeneratedDocuments] gendoc 
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
	OUTER APPLY (
		SELECT 
			SUM(CAST(c.horas_lectivas AS INT)) as horas_totales,
			MIN(c.fecha_inicio) as fecha_inicio, 
			MAX(c.fecha_fin) as fecha_fin,
			MAX(c.Estado_Academico) as Estado_Academico,
			CAST((
				SELECT 
					RTRIM(c2.Curso) as 'nombre',
					CAST(COALESCE(c2.Nota, '0') AS INT) as 'nota',
					CAST(c2.horas_lectivas AS INT) as 'horas'
				FROM CursosConHoras c2
				WHERE c2.Codigo = lista.Codigo 
					AND c2.rn = 1  -- Solo el primer registro por curso
				FOR XML PATH('curso'), ROOT('lista')
			) AS NVARCHAR(MAX)) as asignatura_xml
		FROM CursosConHoras c
		WHERE c.Codigo = lista.Codigo 
			AND c.rn = 1  -- Solo el primer registro por curso para evitar duplicados
	) ax
	WHERE lista.iddocumentofinalreportap = @CodigoDocumentoFinalReportAp 
		AND lista.Tipo_Reporte=4;
		
END