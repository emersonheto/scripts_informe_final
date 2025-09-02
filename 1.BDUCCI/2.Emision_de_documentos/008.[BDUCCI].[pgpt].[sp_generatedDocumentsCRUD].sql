/* ===================================================================================================================
NOMBRE		: [pgpt].[sp_generatedDocumentsCRUD]
FECHA		: 18/11/2022
AUTOR		: José Rios (Proveedor Empresa Zofteam)
OBJETIVO	: Ejecución de operaciones CRUD para registrar y actualizar la generación de documentos
MODIFICACIONES
NRO 	FECHA		USUARIO		    MODIFICACION
01		23/01/2023	APOYODEV4	    Función de autoincremento para insertar en la tabla tblDocuments autocompleta para 6 cifras.
02		20/02/2023	APOYODEV4	    Registro de razón de anulación de documento generado
03		15/05/2023	PRAPPPROY04	    Registro de razón de anulación de documentos sólo para activos
04		29/01/2024  Anthony Torres (NetConsultores) Se agregó la columna Token en el retorno del resultado
05      07/05/2025  EmersonHerrera (waytech)   Se agrega documento 6 Certificaciones de Programas de Especialización AP.
=================================================================================================================== */
ALTER PROCEDURE [pgpt].[sp_generatedDocumentsCRUD]
	@id int,
	@dni varchar(10),
	@seccion varchar(15),
	@archivo varchar(500),
	@tipoConstancia int,
	@estado int,
	@razonAnulacion varchar(MAX),
	@crud varchar(5),
  @iddocumentofinalreportap VARCHAR(20) = NULL
AS
BEGIN
	BEGIN TRY
			BEGIN TRANSACTION

		IF (@crud='I')
		BEGIN
			DECLARE @version int = 0;
			IF exists (SELECT * FROM [pgpt].[tblGeneratedDocuments] WHERE [dni] = @dni AND [seccion] = @seccion AND [tipoConstancia] = @tipoConstancia
                                                    AND (@iddocumentofinalreportap IS NULL OR [iddocumentofinalreportap] = @iddocumentofinalreportap))
			BEGIN
				SELECT top 1 @version = [version]
				FROM [pgpt].[tblGeneratedDocuments]
				WHERE [dni] = @dni 
					AND [seccion] = @seccion 
					AND [tipoConstancia] = @tipoConstancia
                    AND (@iddocumentofinalreportap IS NULL OR [iddocumentofinalreportap] = @iddocumentofinalreportap)
				ORDER BY [version] DESC
			END
			SET @version = @version+1
			IF(@archivo = '') SET @archivo = CONCAT('EPUC.',@seccion,'.',@dni,'.',@version);
			INSERT INTO [pgpt].[tblGeneratedDocuments]
				   ([dni]
				   ,[seccion]
				   ,[archivo]
				   ,[fechaCreacion]
				   ,[tipoConstancia]
				   ,[version]
				   ,[estado]
                   ,[iddocumentofinalreportap])
			 VALUES
				   (
				   @dni
				   ,@seccion
				   ,@archivo
				   ,GETDATE()
				   ,@tipoConstancia
				   ,@version
				   ,@estado
           ,@iddocumentofinalreportap)

			DECLARE @generatedDocumentId INT = @@Identity;
			DECLARE @documentCodeInsertedId INT = 0;
			DECLARE @prefijoDocumentCode VARCHAR(5) = '';
			DECLARE @idDocument INT;
			DECLARE @nomDocumento VARCHAR(100);
			IF(@tipoConstancia = 1)
			BEGIN
				INSERT INTO [pgpt].[tblCodeW] (generatedDocumentId) VALUES (@generatedDocumentId);
				SET @documentCodeInsertedId = @@Identity;
				SET @prefijoDocumentCode = 'W-';
				SELECT top 1 @idDocument = document, @nomDocumento = documentName FROM [BDINTBANNER].[CAU].[TblDocument] WHERE Description = 'EPG-EMDOC-01';
			END
			ELSE IF (@tipoConstancia = 2)
			BEGIN
				INSERT INTO [pgpt].[tblCodeCP] (generatedDocumentId) VALUES (@generatedDocumentId);
				SET @documentCodeInsertedId = @@Identity;
				SET @prefijoDocumentCode = 'CP-';
				SELECT top 1 @idDocument = document, @nomDocumento = documentName FROM [BDINTBANNER].[CAU].[TblDocument] WHERE Description = 'EPG-EMDOC-02';
			END
			ELSE IF (@tipoConstancia in (3,4,6))
			BEGIN
				INSERT INTO [pgpt].[tblCodeD] (generatedDocumentId) VALUES (@generatedDocumentId);
				SET @documentCodeInsertedId = @@Identity;
				SET @prefijoDocumentCode = 'D-';
				IF (@tipoConstancia = 3)
					BEGIN
						SELECT top 1 @idDocument = document, @nomDocumento = documentName FROM [BDINTBANNER].[CAU].[TblDocument] WHERE Description = 'EPG-EMDOC-03';
					END
				ELSE IF (@tipoConstancia = 4)
					BEGIN
						SELECT top 1 @idDocument = document, @nomDocumento = documentName FROM [BDINTBANNER].[CAU].[TblDocument] WHERE Description = 'EPG-EMDOC-04';
					END
				ELSE IF (@tipoConstancia = 6)
					BEGIN
						SELECT top 1 @idDocument = document, @nomDocumento = documentName FROM [BDINTBANNER].[CAU].[TblDocument] WHERE Description = 'EPG-EMDOC-06';
					END
				
			END

			UPDATE [pgpt].[tblGeneratedDocuments]
				SET codigoFormato = CONCAT(@prefijoDocumentCode,@documentCodeInsertedId)
				WHERE id = @generatedDocumentId;


			/* -------------- INSERCIÓN EN TABLA DE DOCUMENTOS DE CAU (BDINTBANNER) ----------------- */
			DECLARE @currentYear VARCHAR(4) = YEAR(getdate());
			DECLARE @incrementId INT = (SELECT top 1 CAST(SUBSTRING(CAST(requestId as VARCHAR(10)), 5,6) AS int) FROM [BDINTBANNER].[CAU].[TblRequest] order by requestId desc)+1;
			DECLARE @codeRequest VARCHAR(10) = CONCAT(@currentYear,RIGHT('000000' + LTRIM(RTRIM(@incrementId)),6));
			DECLARE @divs VARCHAR(5);
			DECLARE @program VARCHAR(5);
			DECLARE @term VARCHAR(8);
			

			DECLARE @pidm int = (SELECT top 1 IDPersonaN FROM dbo.tblPersona WHERE dni = @dni);
			DECLARE @student VARCHAR(300) = (SELECT top 1 CONCAT(UPPER(LEFT(firstLastName COLLATE DATABASE_DEFAULT,1))+LOWER(SUBSTRING(firstLastName COLLATE DATABASE_DEFAULT,2,LEN(firstLastName COLLATE DATABASE_DEFAULT))),' ',
								UPPER(LEFT(secondLastName COLLATE DATABASE_DEFAULT,1))+LOWER(SUBSTRING(secondLastName COLLATE DATABASE_DEFAULT,2,LEN(secondLastName COLLATE DATABASE_DEFAULT))),', ',
								firstName COLLATE DATABASE_DEFAULT) 
									FROM [BDINTBANNER].DIM.tblPerson WHERE documentNumber = @dni );
			DECLARE @requestDescription VARCHAR (250) = CONCAT('{"description":"',@nomDocumento,'","codigoFormato":"',CONCAT(@prefijoDocumentCode,@documentCodeInsertedId),'"}');

			SELECT top 1 @divs=IDDependencia, @program = IDEscuela, @term = CONCAT(REPLACE(IDPerAcad,'-',''),'0')
			FROM dbo.tblseccionc WHERE IDSeccionC = @seccion

			print @codeRequest;

			INSERT INTO [BDINTBANNER].[CAU].[TblRequest]
						([requestID],[divs],[campus],[program],[pidm],[requestDate],[documentNumber],[documentID],[relationshipID]
						,[applicantName],[deliveryDate],[requestStateID],[requestDescription],[officeUserID],[amount],[conceptID],[receiverName]
						,[receiverDocument],[officeID],[term],[aproved],[updateDate],[onlinePaymentID],[Printable],[DeliveredByEmail],[Observations],[JustForBack])
					VALUES
						(@codeRequest
						,@divs
						,'S01'
						,@program
						,@pidm
						,getdate()
						,1
						,@idDocument
						,9
						,@student
						,getdate()
						,100
						,@requestDescription
						,0
						,0
						,null
						,null
						,null
						,69
						,@term
						,1
						,getdate()
						,null
						,1
						,0
						,null
						,0)

			/* -------------- FIN DE INSERCIÓN EN TABLA DE DOCUMENTOS DE CAU (BDINTBANNER) ----------------- */

			SELECT '0' AS IDError, @archivo AS Mensaje, null AS TokenDoc
			UNION ALL
			SELECT '0' AS IDError, CONCAT(@prefijoDocumentCode,@documentCodeInsertedId) AS Mensaje, null AS TokenDoc
		END

		IF (@crud='AN')
		BEGIN
			UPDATE [pgpt].[tblGeneratedDocuments]
				   SET [estado] = 0, [razonAnulacion] = @razonAnulacion
			 WHERE [dni] = @dni AND [seccion] = @seccion AND [tipoConstancia] = @tipoConstancia   
             AND (@iddocumentofinalreportap IS NULL OR [iddocumentofinalreportap] = @iddocumentofinalreportap)
					AND [estado] = 1

			SELECT '0' AS IDError, 'Se archivó correctamente la generación de documento.' AS Mensaje, null AS TokenDoc
		END

		IF (@crud='NTF')
		BEGIN
			UPDATE [pgpt].[tblGeneratedDocuments]
				   SET [estado] = @estado
			 WHERE [dni] = @dni AND [seccion] = @seccion AND [tipoConstancia] = @tipoConstancia AND [estado] = 1
             AND (@iddocumentofinalreportap IS NULL OR [iddocumentofinalreportap] = @iddocumentofinalreportap)

			SELECT '0' AS IDError, 'Se envió correctamente la notificación.' AS Mensaje, null AS TokenDoc
		END


		IF (@crud='U')
		BEGIN
			UPDATE [pgptD].[tblGeneratedDocuments]
				   SET [dni] = @dni
				   ,[seccion] = @seccion
				   ,[archivo] = @archivo
				   ,[estado] = @estado
			 WHERE [dni] = @dni AND [seccion] = @seccion AND [tipoConstancia] = @tipoConstancia
             AND (@iddocumentofinalreportap IS NULL OR [iddocumentofinalreportap] = @iddocumentofinalreportap)

			SELECT '0' AS IDError, 'Se registró correctamente la generación de documento.' AS Mensaje, null AS TokenDoc
		END

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		SELECT '1' AS IDError, CONCAT('Mensaje Error: ',ERROR_MESSAGE(),' Mensaje Severity: ',ERROR_SEVERITY()
								,' Mensaje State: ',ERROR_STATE()) AS Mensaje, null AS TokenDoc
		ROLLBACK TRANSACTION
	END CATCH



END;