USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SHOHIN_SHOSAI_M]') AND type in (N'U'))
DROP TABLE [dbo].[SHOHIN_SHOSAI_M]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[SHOHIN_SHOSAI_M](
	[SSM_HTCD] [int] NOT NULL,
	[SSM_SCD] [bigint] NOT NULL,
	[SSM_NAIYO] [varchar](1000) NULL,
	[SSM_GENZAIRYO] [varchar](1000) NULL,
	[SSM_SEIBUN] [varchar](1000) NULL,
	[SSM_INYMD] [datetime] NOT NULL,
	[SSM_KOSINYMD] [datetime] NOT NULL,
	[SSM_KOSINTIME] [datetime] NOT NULL,
 CONSTRAINT [PK_SHOHIN_SHOSAI_M] PRIMARY KEY CLUSTERED 
(
	[SSM_HTCD] ASC,
	[SSM_SCD] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO