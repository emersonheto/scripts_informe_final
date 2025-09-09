/* ===================================================================================================================
NOMBRE		: [pgpt].[sp_listHistorialSendingDocuments]
FECHA		: 12/05/2023
AUTOR		: José Rios (Proveedor Empresa Zofteam)
OBJETIVO	: Listar historial de documentos generados
MODIFICACIONES
NRO 	FECHA		USUARIO						MODIFICACION
01		08/09/2025  EmersonHerrera (waytech)    Se agrega filtro por codigo de informe final
=================================================================================================================== */
ALTER PROCEDURE [pgpt].[sp_listHistorialSendingDocuments]
	@seccion VARCHAR (10),
	@dni VARCHAR(10),
	@tipoConstancia INT,
	@iddocumentofinalreportap VARCHAR(20) = NULL
AS
BEGIN
	SELECT	[id],
			[dni],
			[seccion],
			[archivo],
			[fechaCreacion],
			[tipoConstancia],
			[version],
			[razonAnulacion],
			[codigoFormato],
			[estado]
	FROM [pgpt].[tblGeneratedDocuments]
	WHERE dni = @dni and tipoConstancia = @tipoConstancia AND seccion = @seccion
	AND (@iddocumentofinalreportap IS NULL OR [iddocumentofinalreportap] = @iddocumentofinalreportap)
	and estado = 0;
END 