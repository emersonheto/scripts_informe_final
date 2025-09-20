USE [BDUCCI]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* ========================================================================================================================
NOMBRE		: [pgpt].[sp_EmiConstanciaSel_UC]
FECHA		: 29/01/2024
AUTOR		: Carlos Marin (NetConsultores)
OBJETIVO	: Obtener la Constancia por InternalId

MODIFICACIONES
NRO	  FECHA			USUARIO							MODIFICACION
01	  14/04/2025	Carlos Estrada(Softbrilliance) 	Ajuste en el nombre del archivo a seleccionar de pgpt.tblGeneratedDocuments
02	  17/09/2025	Emerson Herrera (Waytech)		Se agrega el parámetro iddocumentofinalreportap para la consulta de informe final 
======================================================================================================================== */

ALTER PROCEDURE [pgpt].[sp_EmiConstanciaSel_UC] 
	@InternalId VARCHAR(10)
AS
BEGIN
	SET NOCOUNT ON;
	
	--obtener el director
	DECLARE @idPersona INT
	
	SELECT @idPersona=ValorTexto 
	FROM pgpt.tblEmiParametro_UC
	WHERE Codigo='Direct' 
	
	
	SELECT 
		a.InternalId
	   ,a.Nombres
	   ,a.APPat
	   ,a.APMat
	   ,a.Sede
	   ,a.TipoPrograma
	   ,a.Programa
	   ,a.IDSeccionC
	   ,a.codigoArea
	   ,a.NombreCertificadoConstancia
	   ,a.PeriodoFin
	   ,a.PeriodoInicio
	   ,a.FechaInicio
	   ,a.FechaFin
	   ,a.IDDocumentoGenerado
	   ,a.Creditos
	   ,a.Promedio
	   ,a.Deuda
	   ,a.HorasLectivas
	   ,a.OrdenMerito
	   ,b.dni
	   ,b.archivo
	   ,b.fechaCreacion
	   ,b.tipoConstancia
	   ,b.version
	   ,b.razonAnulacion
	   ,b.codigoFormato
	   ,b.estado
	   ,c.DTipNombre as tipoConstancia_text
	   ,a.InternalId "RowText"
	   ,(SELECT CONCAT(Nombres,' ',Appat,' ',ApMat) FROM tblpersona WHERE IDPersonaN=@idPersona) NombreDirector
	   ,(SELECT top 1 name FROM BDINTBANNER.CAU.TblSignatory WHERE pidm=@idPersona) Cargo
	   ,(SELECT top 1 signature FROM BDINTBANNER.CAU.TblSignatory WHERE pidm=@idPersona) Firma
	   ,(SELECT top 1 seal FROM BDINTBANNER.CAU.TblSignatory WHERE pidm=@idPersona) Sello
	   ,dbo.f_NumeroALetras(a.Promedio) as NotaLetras
	   ,CONCAT('EPUC.',SUBSTRING(b.seccion, 1, 2),'.',SUBSTRING(b.seccion, 3, 3),'.'
	   ,dbo.f_ConversionNumARomano(SUBSTRING(b.seccion, 9, 2)),'.|.',b.dni) AS CodigoCertificado
	   ,(SELECT ISNULL((SELECT Grade FROM gyt.tblpersonal WHERE Pidm=@idPersona),'Mg.')) AS Grado
		 ,a.iddocumentofinalreportap
	FROM pgpt.tblEmiConstancia_UC a
	LEFT JOIN pgpt.tblGeneratedDocuments b 
		ON a.IDDocumentoGenerado=id
	LEFT JOIN dbo.tblDetTipo_UC c 
		ON CAST(b.tipoConstancia AS VARCHAR)=c.DTipCodigo
	WHERE a.InternalId = @InternalId
END;