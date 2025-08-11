USE [BDUCCI]
GO
/* ===================================================================================================================
NOMBRE		: [pgpt].[sp_SelInformeFinalByCodigo_UC]
FECHA		: 03/06/2025
AUTOR		: Emerson Herrera (Waytech)
OBJETIVO	: Listar las certificaciones progresivas de maestrias con el filtro código de informe final. 
=================================================================================================================== */
CREATE  PROCEDURE [pgpt].[sp_SelInformeFinalByCodigo_UC]
    @IdDocumentoFinalReportAp VARCHAR(50),
    @tipoConstancia INT
AS
SET NOCOUNT ON
BEGIN
    SELECT DISTINCT
        per.IDPersonaN AS pidm,
        ISNULL(t.InternalId,0) InternalId,
        per.Nombres,
        per.Appat,
        per.ApMat,
        UPPER(sed.NombreSede) AS Sede,
        'apeM' AS TipoPrograma,
        UPPER(esc.Nombre) AS Programa,
        lista.Seccion AS IDSeccionC,
        lista.Area AS CodigoArea,
        lista.Codigo AS IDAlumno,
        ISNULL(sec.Fecha_Inicio, se.FecInic) AS fecini,
        se.FecFin AS fecfin,
        4 AS IDDocumentoGenerado,
        lista.Codigo AS CodigoEstudiante,
        ISNULL(lista.nombre_constancia_certificado,'') AS NombreConstanciaCertificado,
        NULL AS Promedio,
        NULL AS NivelMerito,
        ISNULL(estado.IDPerAcad, sec.Ciclo) AS PeriodoInicio,
        ISNULL(estado.IDPerAcad, sec.Ciclo) AS PeriodoFin,
        0 AS HorasLectivas,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM dbo.tblCtaCorriente cta
                WHERE cta.IDAlumno = lista.Codigo 
                    AND cta.IDSeccionC = lista.Seccion
                    AND cta.Deuda > 0
                    AND CONVERT(DATE, cta.FecCargo) <= CONVERT(DATE, GETDATE())
            ) THEN 'Tiene deuda'
            ELSE ''
        END AS Motivo,
        CASE WHEN t.InternalId IS NOT NULL THEN 1 ELSE 0 END AS EstadoDocGenerado,
				0 AS Desaprobado
    FROM dbo.tblInfFinalDatosdelosEstudiantes lista
    INNER JOIN dbo.tblDocumentoFinalReportAp drf 
        ON lista.IdDocumentoFinalReportAp = drf.IdDocumentoFinalReportAp
    LEFT JOIN dbo.tblPersona per 
        ON lista.Codigo = per.DNI     
    LEFT JOIN dbo.tblseccionC se 
        ON se.IDSeccionC = lista.Seccion
    LEFT JOIN dbo.tblAlumnoEstado estado 
        ON per.DNI = estado.IDAlumno AND estado.IDSeccionC = se.IDSeccionC
    LEFT JOIN dbo.tblSede sed 
        ON estado.IDSede = sed.IDSede
    LEFT JOIN dbo.tblInfFinalSeccionCertificar sec  
        ON lista.Seccion = sec.Seccion AND sed.NombreSede = sec.Nombre_Sede
    LEFT JOIN dbo.tblEscuela esc 
        ON esc.IDEscuela = se.IDEscuela AND esc.IDDependencia = 'UCCI'
    LEFT JOIN pgpt.tblGeneratedDocuments gendoc 
        ON gendoc.id = (
            SELECT TOP 1 id
            FROM pgpt.tblGeneratedDocuments gd
            WHERE gd.dni = lista.Codigo 
              AND gd.seccion = lista.Seccion 
              AND gd.tipoConstancia = @tipoConstancia
              AND gd.estado IN (1,2,3,4)
            ORDER BY version DESC
        )
    LEFT JOIN pgpt.tblEmiConstancia_UC t ON t.IdDocumentoGenerado = gendoc.id AND t.IDSeccionC=lista.Seccion AND t.codigoArea=lista.Area
    WHERE esc.IDTipoEsc IN ('ECO', 'POS') 
      AND drf.IdDocumentoFinalReportAp = @IdDocumentoFinalReportAp;
END;

