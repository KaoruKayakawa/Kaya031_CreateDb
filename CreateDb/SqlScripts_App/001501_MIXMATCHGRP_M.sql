USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MIXMATCHGRP_M]') AND type in (N'U'))
DROP TABLE [dbo].[MIXMATCHGRP_M]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MIXMATCHGRP_M](
	[MGM_HTCD] [int] NOT NULL,
	[MGM_MMNO] [int] NOT NULL,
	[MGM_MMNAME] [varchar](60) NOT NULL,
	[MGM_MMSTR] [datetime] NOT NULL,
	[MGM_MMEND] [datetime] NOT NULL,
	[MGM_SETKOSU] [int] NOT NULL,
	[MGM_SETKINGAKU] [int] NOT NULL,
	[MGM_TAXKBN] [tinyint] NULL,
	[MGM_INYMD] [datetime] NOT NULL,
	[MGM_KOSINYMD] [datetime] NOT NULL,
	[MGM_KOSINTIME] [datetime] NOT NULL,
 CONSTRAINT [PK_MIXMATCHGRP_M] PRIMARY KEY CLUSTERED 
(
	[MGM_HTCD] ASC,
	[MGM_MMNO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO