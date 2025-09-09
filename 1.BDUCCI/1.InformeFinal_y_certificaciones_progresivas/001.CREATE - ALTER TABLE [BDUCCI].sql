USE [BDUCCI]
GO
/*====================================================================================================
NOMBRE	: dbo.tblInfFinalConsolidadoNotasEstudiantesRecuperadosCursos
FECHA	: 08/09/2025
AUTOR	: Emerson Herrera(Waytech)
OBJETIVO: se crean tablas y se añaden columnas necesarias

====================================================================================================*/
--Tabla para guardar los datos del informe final de memorandum de recuperados
CREATE TABLE dbo.tblInfFinalMemorandumFinalReportAp(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Seccion varchar(50) NOT NULL,
    SeccionOrigen varchar(50),
    Codigo varchar(50) NOT NULL,
    ApellidosNombres varchar(200) NOT NULL,
    TipoPrograma varchar(50) NOT NULL,
    Programa varchar(200) NOT NULL,
    Asignatura varchar(200) NOT NULL,
    EstadoAcademico varchar(50) NOT NULL,
    NotaFinal varchar(20) NOT NULL,
    FechaRegistro datetime NULL,
    FechaEdicion datetime NULL,
    UsuarioCreacion varchar(200) NOT NULL,
    ProgramaCodigo varchar(3) NULL,
    IdDocumentoFinalReportAp varchar(50) NULL
)

--tabla para guardar los datos de configuración de cabecera para el documento MEMORANDUM
CREATE TABLE dbo.tblDatosMemoFinalReportAp (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    NombreEncargado VARCHAR(200) NOT NULL,
    Cargo VARCHAR(200) NOT NULL,
    Uni VARCHAR(200) NOT NULL,
    NombreCargo VARCHAR(200) NOT NULL,
    Ciudad VARCHAR(100) NOT NULL,
    NroEdicionA VARCHAR(5),
    NroEdicionB VARCHAR(5),
    Monto DECIMAL(10,2) NOT NULL
);

ALTER TABLE [dbo].[tblInfFinalConsolidadoNotasEstudiantesRecuperadosCursos] ADD [Area] varchar(20) NULL
GO
ALTER TABLE [dbo].[tblInfFinalConsolidadoNotasEstudiantesRecuperadosCursos] ALTER COLUMN [Seccion] varchar(50)  NULL
GO
--Agregar columnas en tabla Certificacion
ALTER TABLE [dbo].[tblInfFinalSeccionCertificar] ADD    
    [Programa_Codigo] VARCHAR(3),
    [IdDocumentoFinalReportAp] VARCHAR(50)
GO
--va a permitir saber a partir de qué id temporal se creó el id definitivo
ALTER TABLE [dbo].[tblDocumentoFinalReportAp] ADD
    [IdDocumentoFinalReportApTMP] VARCHAR(50)
GO
ALTER TABLE [dbo].[tblInfFinalResultadoParticipantes2FinalReportAp] ALTER COLUMN [Seccion] varchar(50) NULL
GO
ALTER TABLE [dbo].[tblInfFinalResultadoParticipantes1FinalReportAp] ALTER COLUMN [Seccion] varchar(50) NULL
GO
ALTER TABLE [dbo].[tblInfFinalResultadoNotasParticipantesCursos] ALTER COLUMN [Seccion] varchar(50) NULL
GO
ALTER TABLE [dbo].[tblInfFinalCertificacionPrograma] ALTER COLUMN [Seccion] varchar(50)  NULL



