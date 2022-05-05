USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UPDATE_PENDING]') AND type in (N'U'))
DROP TABLE [dbo].[UPDATE_PENDING]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[UPDATE_PENDING](
	[UDP_TBL] [nvarchar](50) NOT NULL,
	[UDP_KCD] [int] NOT NULL,
	[UDP_HTCD] [int] NOT NULL,
	[UDP_TEKIYOYMD] [datetime] NOT NULL,
	[UDP_UPDATECNT] [int] NOT NULL,
	[UDP_KEY1] [sql_variant] NULL,
	[UDP_KEY2] [sql_variant] NULL,
	[UDP_KEY3] [sql_variant] NULL,
	[UDP_KEY4] [sql_variant] NULL,
	[UDP_KEY5] [sql_variant] NULL,
	[UDP_NOTE] [nvarchar](100) NULL,
	[UDP_TENCD] [int] NOT NULL,
) ON [PRIMARY]
GO
