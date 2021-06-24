--1 Hacer un trigger que al cargar un crédito verifique que el importe del mismo sumado a los importes
-- de los créditos que actualmente solicitó esa persona no supere al triple de la declaración de
-- ganancias. Sólo deben tenerse en cuenta en la sumatoria los créditos que no se encuentren 
--cancelados. De no poder otorgar el crédito aclararlo con un mensaje.

CREATE TRIGGER TR_AutorizarCredito ON creditos
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @ImporteT money
	DECLARE @IDDNI VARCHAR
	
	DECLARE @ID BIGINT
	DECLARE @IDBANCO INT
	DECLARE @FECHA DATE
	DECLARE @PLAZO SMALLINT
	DECLARE @CANCELADO BIT
	DECLARE @IMPORTE MONEY

	SELECT @ID = ID FROM inserted
	SELECT @IDBANCO = IDBANCO FROM inserted
	SELECT @FECHA = Fecha FROM inserted
	SELECT @PLAZO = Plazo FROM inserted
	SELECT @CANCELADO = @CANCELADO FROM inserted
	SELECT @Importe = Importe FROM inserted
	

	SELECT @IDDNI = DNI FROM inserted
	--sumar creditos pedidos. Solo los no cancelados
	SELECT @ImporteT= SUM(Importe) FROM creditos
	WHERE @IDDNI = DNI AND CANCELADO=0

	DECLARE @DECLARACIONX3 MONEY
	SELECT @DECLARACIONX3=(3*DeclaracionGanancias) FROM Personas
	WHERE DNI=@IDDNI

	--no supere el triple de la declaraciondeganancias
		IF @DECLARACIONX3 > @ImporteT BEGIN
		--mensaje de error
		 PRINT 'NO SE PUEDE REALIZAR SOLICITUD YA QUE SUPERA EL MAX DE CREDITO DISPONIBLE'
		 ROLLBACK
		END

	--hacer insert
	INSERT INTO CREDITOS(id,idbanco,dni,fecha,importe,plazo,cancelado)
	values (@ID,@IDBANCO,@IDDNI,@FECHA,@Importe, @IMPORTE,@plazo,@cancelado)
END
GO

--2 Hacer un trigger que al eliminar un crédito realice la cancelación del mismo.

CREATE TRIGGER TR_EliminarCredito ON Creditos
INSTEAD OF DELETE
AS
BEGIN

DECLARE @IDCredito bigint
SELECT @IDCredito = ID FROM deleted

UPDATE Creditos SET Cancelado=1 WHERE @IDCredito=ID

END
GO
--3 Hacer un trigger que no permita otorgar créditos con un plazo de 20 o más años a personas cuya
-- declaración de ganancias sea menor al promedio de declaración de ganancias.

CREATE TRIGGER TR_OtorgarCredito20Anios ON Creditos
INSTEAD OF INSERT
AS
BEGIN
-- BUSCAR EL PROMEDIO DE GANANCIAS
DECLARE @PROMEDIO MONEY

SELECT @PROMEDIO= AVG(DeclaracionGanancias) FROM Personas

--FIJAR DE QUE EL PLAZO DEL CREDITO NO SEA MAYOR A 20 AÑOS

	DECLARE @ID BIGINT
	DECLARE @IDBANCO INT
	DECLARE @FECHA DATE
	DECLARE @PLAZO SMALLINT
	DECLARE @CANCELADO BIT
	DECLARE @IMPORTE MONEY
	DECLARE @IDDNI VARCHAR
	SELECT @ID = ID FROM inserted
	SELECT @IDBANCO = IDBANCO FROM inserted
	SELECT @FECHA = Fecha FROM inserted
	SELECT @PLAZO = Plazo FROM inserted
	SELECT @CANCELADO = @CANCELADO FROM inserted
	SELECT @Importe = Importe FROM inserted
	SELECT @IDDNI = DNI FROM inserted

DECLARE @GANANCIAS MONEY

SELECT @GANANCIAS = DeclaracionGanancias FROM PERSONAS
WHERE @IDDNI= DNI

IF @GANANCIAS < @PROMEDIO AND @PLAZO<20 BEGIN
RAISERROR ('NO ES POSIBLE OTORGAR EL CREDITO YA QUE NO SUPERA EL PROMEDIO DE GANANCIAS. SOLICITE PLAZO MENOR A 20 AÑOS',13,1)
END

INSERT INTO Creditos(ID, IDBanco,DNI,Fecha,Importe,Plazo,Cancelado)
VALUES(@ID,@IDBANCO,@IDDNI,@FECHA,@Importe,@PLAZO,@CANCELADO)

END
GO

--4 Hacer un procedimiento almacenado que reciba dos fechas y liste todos los créditos otorgados entre
-- esas fechas. Debe listar el apellido y nombre del solicitante,
-- el nombre del banco, el tipo de banco, la fecha del crédito y el importe solicitado.


CREATE PROCEDURE CreditoEntreFechas(
@FechaInicio DATE,
@FechaFin DATE
)
AS
BEGIN 
SELECT P.nombres,P.Apellidos,B.nombre,B.tipo,C.fecha,C.Importe FROM Creditos AS C
INNER JOIN Personas AS P ON P.DNI = C.DNI
INNER JOIN Bancos AS B ON B.id= c.IDbanco
WHERE C.Fecha<@FechaFin AND C.fecha >@FechaInicio
END
