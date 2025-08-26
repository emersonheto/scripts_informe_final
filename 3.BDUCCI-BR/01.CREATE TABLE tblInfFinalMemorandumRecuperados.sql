USE [BDUCCI]
GO
/* ===================================================================================================================
FECHA		: 03/06/2025
AUTOR		: Brus Paucar (WAYTECH)
OBJETIVO	: crear tablas para la sección MEMORANDUM
=================================================================================================================== */
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