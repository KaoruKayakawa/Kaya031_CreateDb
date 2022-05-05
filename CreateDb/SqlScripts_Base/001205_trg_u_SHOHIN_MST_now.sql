USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[trg_u_SHOHIN_MST_now]') AND type in (N'TR'))
DROP TRIGGER [dbo].[trg_u_SHOHIN_MST_now]
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
CREATE TRIGGER [dbo].[trg_u_SHOHIN_MST_now]
   ON  [dbo].[SHOHIN_MST_now]
   INSTEAD OF UPDATE
AS 
BEGIN
	SET NOCOUNT ON;
	
	RAISERROR(50002, 11, 1);
END

GO

ALTER TABLE [dbo].[SHOHIN_MST_now] ENABLE TRIGGER [trg_u_SHOHIN_MST_now]
GO
