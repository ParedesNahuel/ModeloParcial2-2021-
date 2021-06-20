--1 Hacer un trigger que al cargar un cr�dito verifique que el importe del mismo sumado a los importes
-- de los cr�ditos que actualmente solicit� esa persona no supere al triple de la declaraci�n de
-- ganancias. S�lo deben tenerse en cuenta en la sumatoria los cr�ditos que no se encuentren 
--cancelados. De no poder otorgar el cr�dito aclararlo con un mensaje.

CREATE TRIGGER TR_AutorizarCredito ON creditos
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @ImporteT money
	DECLARE @IDDNI VARCHAR

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
END
GO

--2 Hacer un trigger que al eliminar un cr�dito realice la cancelaci�n del mismo.

CREATE TRIGGER TR_EliminarCredito ON Creditos
INSTEAD OF DELETE
AS
BEGIN

DECLARE @IDCredito bigint
SELECT @IDCredito = ID FROM deleted

UPDATE Creditos SET Cancelado=1 WHERE @IDCredito=ID

END
GO
--3 Hacer un trigger que no permita otorgar cr�ditos con un plazo de 20 o m�s a�os a personas cuya
-- declaraci�n de ganancias sea menor al promedio de declaraci�n de ganancias.

CREATE TRIGGER TR_OtorgarCredito20Anios ON Creditos
INSTEAD OF INSERT
AS
BEGIN
-- BUSCAR EL PROMEDIO DE GANANCIAS
DECLARE @PROMEDIO MONEY

SELECT @PROMEDIO= AVG(DeclaracionGanancias) FROM Personas

--FIJAR DE QUE EL PLAZO DEL CREDITO NO SEA MAYOR A 20 A�OS
DECLARE @IDDNI VARCHAR

SELECT @IDDNI = DNI FROM inserted

DECLARE @GANANCIAS MONEY
DECLARE @PLAZO SMALLINT

SELECT @GANANCIAS = DeclaracionGanancias FROM PERSONAS
WHERE @IDDNI= DNI

SELECT @PLAZO= PLAZO FROM INSERTED
WHERE @IDDNI= DNI

IF @GANANCIAS < @PROMEDIO AND @PLAZO<20 BEGIN
RAISERROR ('NO ES POSIBLE OTORGAR EL CREDITO YA QUE NO SUPERA EL PROMEDIO DE GANANCIAS. SOLICITE PLAZO MENOR A 20 A�OS',13,1)
END

END
GO

--4 Hacer un procedimiento almacenado que reciba dos fechas y liste todos los cr�ditos otorgados entre
-- esas fechas. Debe listar el apellido y nombre del solicitante,
-- el nombre del banco, el tipo de banco, la fecha del cr�dito y el importe solicitado.


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