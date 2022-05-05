USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_AddErrorMsg_DB]') AND type in (N'P'))
DROP PROCEDURE [dbo].[sp_AddErrorMsg_DB]
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
CREATE PROCEDURE [dbo].[sp_AddErrorMsg_DB]
AS
BEGIN
	SET NOCOUNT ON;
	
	EXECUTE sp_addmessage @msgnum = 59999,
					@severity = 11,
					@msgtext = N'SQL Server System Error：[%d] %s',
					@lang = 'us_english',
					@replace = 'replace';
	EXECUTE sp_addmessage @msgnum = 59999,
					@severity = 11,
					@msgtext = N'SQL Server システム エラー：[%1!] %2!',
					@lang = 'Japanese',
					@replace = 'replace';

	EXECUTE sp_addmessage @msgnum = 50001,
					@severity = 11,
					@msgtext = N'The record of table [%s] was updated by other processing.',
					@lang = 'us_english',
					@replace = 'replace';
	EXECUTE sp_addmessage @msgnum = 50001,
					@severity = 11,
					@msgtext = N'テーブル [%1!] の指定レコードは、他の処理で更新されました。',
					@lang = 'Japanese',
					@replace = 'replace';

	EXECUTE sp_addmessage @msgnum = 50002,
					@severity = 11,
					@msgtext = N'You cannot perform the operation.',
					@lang = 'us_english',
					@replace = 'replace';
	EXECUTE sp_addmessage @msgnum = 50002,
					@severity = 11,
					@msgtext = N'操作は許可されていません。',
					@lang = 'Japanese',
					@replace = 'replace';
END

GO

EXEC sp_AddErrorMsg_DB
GO
