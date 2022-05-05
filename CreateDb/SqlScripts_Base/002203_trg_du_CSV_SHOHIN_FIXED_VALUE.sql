USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[trg_du_CSV_SHOHIN_FIXED_VALUE]') AND type in (N'TR'))
DROP TRIGGER [dbo].[trg_du_CSV_SHOHIN_FIXED_VALUE]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		kayakawa
-- Create date:
-- Description:	
-- =============================================
CREATE TRIGGER [dbo].[trg_du_CSV_SHOHIN_FIXED_VALUE]
   ON  [dbo].[CSV_SHOHIN_FIXED_VALUE]
   AFTER DELETE, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    INSERT INTO CSV_SHOHIN_FIXED_VALUE_HISTORY
	SELECT *, GETDATE()
	FROM deleted;
END

GO

ALTER TABLE [dbo].[CSV_SHOHIN_FIXED_VALUE] ENABLE TRIGGER [trg_du_CSV_SHOHIN_FIXED_VALUE]
GO
