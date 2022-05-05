USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[trg_d_MIKEISAI_SCD_MST_now]') AND type in (N'TR'))
DROP TRIGGER [dbo].[trg_d_MIKEISAI_SCD_MST_now]
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
CREATE TRIGGER [dbo].[trg_d_MIKEISAI_SCD_MST_now]
   ON  [dbo].[MIKEISAI_SCD_MST_now]
   INSTEAD OF DELETE
AS 
BEGIN
	SET NOCOUNT ON;
	
	RAISERROR(50002, 11, 1);
END

GO

ALTER TABLE [dbo].[MIKEISAI_SCD_MST_now] ENABLE TRIGGER [trg_d_MIKEISAI_SCD_MST_now]
GO
