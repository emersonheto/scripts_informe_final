/* ========================================================================================================================
NOMBRE		: [pgpt].[sp_EmiConstanciaIns_UC]
FECHA		: 29/01/2024
AUTOR		: Cristian Jesus (NetConsultores)
OBJETIVO	: Realiza el INSERT en la tabla pgpt.tblEmiConstancia_UC

MODIFICACIONES
NRO		FECHA		USUARIO							MODIFICACION
1		21/05/2024	Carlos Marín (NetConsultores) 	Ajuste en la descripción de puestos y modificación del query para traer los cursos
2		14/04/2025	Carlos Estrada(Softbrilliance) 	Ajuste en el nombre del archivo a insertar en pgpt.tblGeneratedDocuments
3		20/05/2025	Emerson Herrera(Waytech)		Se agrega un nuevo tipo de constancia [9] para certificación progresiva de programas de maestrías.	
4       17/09/2025  Emerson Herrera(Waytech)		Se agrega el parámetro iddocumentofinalreportap para la inserción.
======================================================================================================================== */
ALTER PROCEDURE [pgpt].[sp_EmiConstanciaIns_UC]
    @Nombres VARCHAR(50)= NULL,
    @APPat VARCHAR(50)= NULL,
    @APMat VARCHAR(50)= NULL,
    @Sede VARCHAR(100)= NULL,
    @TipoPrograma VARCHAR(20)= NULL,
    @Programa VARCHAR(500)= NULL,
    @CodigoArea VARCHAR(10)= NULL,
    @NombreCertificadoConstancia VARCHAR(500)= NULL,
    @PeriodoInicio VARCHAR(50)= NULL,
    @PeriodoFin VARCHAR(50)= NULL,
    @Creditos INT= NULL,
    @Promedio NUMERIC(5, 2)= NULL,
    @Deuda INT= NULL,
    @HorasLectivas NUMERIC(5,2)= NULL,
    @OrdenMerito VARCHAR(7)= NULL,
    @Cargo VARCHAR(100)= NULL,
    @NombreDirector VARCHAR(100)=NULL,
	@dni VARCHAR(20) =NULL,
	@seccion VARCHAR(15) = NULL,
	@tipoConstancia INT = NULL,
	@FechaIni VARCHAR(30) =NULL,
	@FechaFin VARCHAR(30) = NULL,
	@iddocumentofinalreportap VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
	
	--insertar datos tabla tblgeneratedDocuments
	DECLARE @TipoCertificado VARCHAR(10)
	DECLARE @BODY VARCHAR(10)
	IF @tipoConstancia = 5 OR  @tipoConstancia =9
	BEGIN
	    SET @TipoCertificado = '.CP.';
	    SET @BODY = '-CP-';
	END
	ELSE IF @tipoConstancia = 6
	BEGIN
	    SET @TipoCertificado = '.OM.';
	    SET @BODY = '-OMPE-';
	END
	ELSE IF @tipoConstancia = 7
	BEGIN
	    SET @TipoCertificado = '.OM.';
	    SET @BODY = '-OMMA-';
	END

	
	DECLARE @AnioActual CHAR(2)
    DECLARE @NumeroSiguiente INT
	
    SET @AnioActual = RIGHT(YEAR(GETDATE()), 2)

    SELECT @NumeroSiguiente = ISNULL(MAX(CAST(RIGHT(codigoFormato, 6) AS INT)), 0) + 1
		FROM pgpt.tblGeneratedDocuments
		WHERE SUBSTRING(codigoFormato, 1, 2) = @AnioActual AND tipoconstancia =@tipoConstancia

    DECLARE @NombreArchivo VARCHAR(20)
    SET @NombreArchivo = @AnioActual + @BODY + RIGHT('00000' + CAST(@NumeroSiguiente AS VARCHAR(6)), 6)
		
		DECLARE @CodigoDocumento VARCHAR(100)
		IF @tipoConstancia = 9
			SET @CodigoDocumento =CONCAT('EPUC.',@seccion,'.',@CodigoArea,'.',@dni)
		ELSE
			SET @CodigoDocumento =CONCAT('EPUC',@TipoCertificado,@seccion,'.',@CodigoArea,'.',@dni)


	    INSERT INTO pgpt.tblGeneratedDocuments (dni,seccion,archivo,fechaCreacion,tipoConstancia,version,razonAnulacion,codigoFormato,estado,iddocumentofinalreportap)
		VALUES (
			@dni,@seccion,@CodigoDocumento ,GETDATE(),@tipoConstancia,1,'',@NombreArchivo,1,@iddocumentofinalreportap
	);

	DECLARE @IDDocumentoGenerado INT;
    SET @IDDocumentoGenerado = SCOPE_IDENTITY();

	--Cambiar nombre de puestos por numeros

	IF @OrdenMerito IS NOT NULL
	BEGIN
		SELECT @OrdenMerito = CASE @OrdenMerito
		  WHEN 'Primer ' THEN '1er'
		  WHEN 'Segundo' THEN '2do'
		  WHEN 'Tercer ' THEN '3er'
		  ELSE ''
		END;
	END


    -- Insertar datos en la tabla tblEmiConstancia_UC
    INSERT INTO pgpt.tblEmiConstancia_UC (Nombres, APPat, APMat, Sede, TipoPrograma, Programa, IDSeccionC, codigoArea,
        NombreCertificadoConstancia, PeriodoInicio,PeriodoFin,FechaInicio,FechaFin,IDDocumentoGenerado, Creditos, Promedio, Deuda, HorasLectivas,
        OrdenMerito, cargo, NombreDirector,iddocumentofinalreportap)
    VALUES (@Nombres, @APPat, @APMat, @Sede, @TipoPrograma, @Programa, @seccion, @CodigoArea,
        @NombreCertificadoConstancia,@PeriodoInicio,@PeriodoFin,@FechaIni,@FechaFin,@IDDocumentoGenerado, @Creditos, @Promedio, @Deuda, @HorasLectivas,
        @OrdenMerito, '', '',@iddocumentofinalreportap);
		DECLARE @IdEmiConstancia INT;
    SET @IdEmiConstancia = SCOPE_IDENTITY();
	-- Insetar datos en la tabla [tblEmiConstanciaAsignaturas_UC]
	

	--llamada a BANNER para insertar las notas

	DECLARE @table table
(
	Nota INT,
	Curso NVARCHAR(200),
	Creditos INT
)

DECLARE @Sql NVARCHAR(MAX)
SET @Sql = 'SELECT * FROM Openquery(BANNER,'''

		SET @Sql = @Sql + ' SELECT B.SFRSTCR_GRDE_CODE AS Nota, '
		SET @Sql = @Sql + ' I.ASIGNATURA as Curso, '
		SET @Sql = @Sql + ' B.SFRSTCR_CREDIT_HR as Creditos '
		SET @Sql = @Sql + ' FROM SPRIDEN A '
		SET @Sql = @Sql + ' INNER JOIN sfrstcr B ON B.sfrstcr_pidm=A.SPRIDEN_PIDM '
		SET @Sql = @Sql + ' INNER JOIN sorlcur C ON C.sorlcur_pidm = B.sfrstcr_pidm '
		SET @Sql = @Sql + ' INNER JOIN stvmajr D ON C.sorlcur_program = D.stvmajr_code '
		SET @Sql = @Sql + ' INNER JOIN stvcamp E ON B.sfrstcr_camp_code = E.stvcamp_code '
		SET @Sql = @Sql + ' INNER JOIN SSBSECT F ON F.SSBSECT_CRN=B.SFRSTCR_CRN AND B.SFRSTCR_TERM_CODE=F.SSBSECT_TERM_CODE '
		SET @Sql = @Sql + ' INNER JOIN SMRARUL G ON F.SSBSECT_SUBJ_CODE=SUBSTR(G.SMRARUL_KEY_RULE,1,4) AND F.SSBSECT_CRSE_NUMB=SUBSTR(G.SMRARUL_KEY_RULE,5,5) '
		SET @Sql = @Sql + ' INNER JOIN SMRALIB H ON H.SMRALIB_AREA=G.SMRARUL_AREA '
		SET @Sql = @Sql + ' INNER JOIN SZVMALLA I on I.PROGRAM = C.SORLCUR_PROGRAM AND I.RULE_SUBJ_CODE || I.RULE_CRSE_NUMB = F.SSBSECT_SUBJ_CODE || F.SSBSECT_CRSE_NUMB '
--		SET @Sql = @Sql + ' AND I.TERM_CODE_EFF = B.SFRSTCR_TERM_CODE '
		SET @Sql = @Sql + ' WHERE  B.sfrstcr_blck_code is not null AND C.sorlcur_cact_code  = ''''ACTIVE'''' '
		-- SET @Sql = @Sql + ' AND B.sfrstcr_blck_code='''''+@seccion+''''' AND G.SMRARUL_AREA='''''+@CodigoArea+''''' AND A.SPRIDEN_ID='''''+@dni+''''' '
		
		-- Aplicar filtro de sección solo si @iddocumentofinalreportap es nulo || validando si proviene de Informe Final Certificaciones progresivas 
		IF @iddocumentofinalreportap IS NULL
				SET @Sql = @Sql + ' AND B.sfrstcr_blck_code='''''+@seccion+''''' AND G.SMRARUL_AREA='''''+@CodigoArea+''''' AND A.SPRIDEN_ID='''''+@dni+''''' '
		ELSE
				SET @Sql = @Sql + ' AND G.SMRARUL_AREA='''''+@CodigoArea+''''' AND A.SPRIDEN_ID='''''+@dni+''''' '
	
		
		SET @Sql = @Sql + ' GROUP BY I.ASIGNATURA,B.SFRSTCR_GRDE_CODE,B.SFRSTCR_CREDIT_HR '
		SET @Sql = @Sql + ' ORDER BY I.ASIGNATURA asc '
   		SET @Sql = @Sql + '     '');'

		INSERT INTO @table(Nota,Curso,Creditos)
		EXEC sp_executesql @Sql;


	INSERT INTO pgpt.tblEmiConstanciaAsignaturas_UC (
	      EmiConstancia,Asignatura,Creditos,Nota
	)
	SELECT @IdEmiConstancia,Curso,Creditos,Nota FROM @table

    SELECT @IdEmiConstancia AS 'NuevoInternalId';
END;