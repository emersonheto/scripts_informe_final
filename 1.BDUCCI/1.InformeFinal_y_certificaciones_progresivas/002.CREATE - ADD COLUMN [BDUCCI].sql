USE [BDUCCI]
GO
/* ===================================================================================================================
FECHA		: 03/06/2025
AUTOR		: Brus Paucar (WAYTECH)
OBJETIVO	: Crear tablas y añadir columnas a tablas existentes
=================================================================================================================== */
    --Crear tabla para codigos Informe Final
    CREATE TABLE [dbo].[tblCodigoInformeFinal](
        Id INT IDENTITY(1,1) PRIMARY KEY,
        IdAnio AS RIGHT(CAST(YEAR(GETDATE()) AS VARCHAR(4)), 2),
        IdInforme VARCHAR(5),
        IdDocumento VARCHAR(5),
        IdPrograma VARCHAR(5),
        IdSede VARCHAR(5),
        NroCorrelativo INT
    )

    --Crear tabla para el Informe Final
    CREATE TABLE [dbo].[tblDocumentoFinalReportAp] (
        IdDocumentoFinalReportAp VARCHAR(15) PRIMARY KEY,
        PathDocumento VARCHAR(255),
        FechaRegistro DATETIME NOT NULL,
        FechaEdicion DATETIME,
        UsuarioCreacion VARCHAR(200) NOT NULL,
        TipoReporte INT
    )

    --Agregar columnas en tabla de docentes
    ALTER TABLE [dbo].[tblInfFinalProgramacionDocente] ADD
        [Programa] VARCHAR(1000),
        [Programa_Codigo] VARCHAR(3),
        [IdDocumentoFinalReportAp] VARCHAR(50)

    --Crear tabla Tipo Alumno Resumen
    CREATE TABLE [dbo].[tblInfFinalResultadoParticipantes1FinalReportAp] (
        IdResPart1 INT IDENTITY(1,1) PRIMARY KEY,
        Seccion VARCHAR(50) NOT NULL,
        Tipo_Alumno VARCHAR(200) NOT NULL,
        Nro_Estudiantes INT,
        Fecha_Registro DATETIME,
        Fecha_Edicion DATETIME,
        Tipo_Reporte INT,
        Usuario_Creacion VARCHAR(200),
        Area VARCHAR(20),
        Programa VARCHAR(1000) NOT NULL,
        Programa_Codigo VARCHAR(3) NOT NULL,
        IdDocumentoFinalReportAp VARCHAR(50) NOT NULL
    )

    --Crear tabla Resultado Alumno Resumen
    CREATE TABLE [dbo].[tblInfFinalResultadoParticipantes2FinalReportAp] (
        IdResPar2 INT IDENTITY(1,1) PRIMARY KEY,
        Seccion VARCHAR(50) NOT NULL,
        Estado VARCHAR(200) NOT NULL,
        Nro_Estudiantes INT,
        Fecha_Registro DATETIME,
        Fecha_Edicion DATETIME,
        Tipo_Reporte INT,
        Usuario_Creacion VARCHAR(200) NOT NULL,
        Area VARCHAR(20),
        Programa VARCHAR(1000) NOT NULL,
        Programa_Codigo VARCHAR(3) NOT NULL,
        IdDocumentoFinalReportAp VARCHAR(50) NOT NULL
    )

    --Agregar columnas en tabla Notas Detalle
    ALTER TABLE [dbo].[tblInfFinalResultadoNotasParticipantesCursos] ADD
        [Programa] VARCHAR(1000),
        [Programa_Codigo] VARCHAR(3),
        [IdDocumentoFinalReportAp] VARCHAR(50)

    --Agregar columnas en tabla Resumen
    ALTER TABLE [dbo].[tblInfFinalResultadoNotasParticipantes] ADD
        [Programa] VARCHAR(1000),
        [Programa_Codigo] VARCHAR(3),
        [IdDocumentoFinalReportAp] VARCHAR(50)

    --Agregar columnas en tabla Notas Recuperadas Resumen
    ALTER TABLE [dbo].[tblInfFinalConsolidadoNotasEstudiantesRecuperados] ADD
        [Programa] VARCHAR(1000),
        [Programa_Codigo] VARCHAR(3),
        [IdDocumentoFinalReportAp] VARCHAR(50)

    --Agregar columnas en tabla Orden de Merito
    ALTER TABLE [dbo].[tblInfFinalResultadoOrdenMeritoParticipantes] ADD
        [Programa] VARCHAR(1000),
        [Programa_Codigo] VARCHAR(3),
        [IdDocumentoFinalReportAp] VARCHAR(50)

    --Agregar columnas en tabla Certificacion
    ALTER TABLE [dbo].[tblInfFinalCertificacionPrograma] ADD
        [Programa] VARCHAR(1000),
        [Programa_Codigo] VARCHAR(3),
        [IdDocumentoFinalReportAp] VARCHAR(50)

    --Agregar columnas en tabla Datos Estudiante
    ALTER TABLE [dbo].[tblInfFinalDatosdelosEstudiantes] ADD
        [Programa] VARCHAR(1000),
        [Programa_Codigo] VARCHAR(3),
        [Nombre_constancia_certificado] VARCHAR(1000),
        [IdDocumentoFinalReportAp] VARCHAR(50)
        

    --Agregar columnas en tabla Notas Recuperadas Detalle
    ALTER TABLE [dbo].[tblInfFinalConsolidadoNotasEstudiantesRecuperadosCursos] ADD
        [Programa] VARCHAR(1000),
        [Programa_Codigo] VARCHAR(3),
        [IdDocumentoFinalReportAp] VARCHAR(50)

    --Agregar columnas en tabla Anexos
    ALTER TABLE [dbo].[tblInfFinalAnexos] ADD
        [IdDocumentoFinalReportAp] VARCHAR(50)
