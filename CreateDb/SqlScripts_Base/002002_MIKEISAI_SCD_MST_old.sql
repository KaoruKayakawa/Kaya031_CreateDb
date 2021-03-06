USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MIKEISAI_SCD_MST_old]') AND type in (N'U'))
DROP TABLE [dbo].[MIKEISAI_SCD_MST_old]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MIKEISAI_SCD_MST_old](
	[MKS_KCD] [int] NOT NULL,
	[MKS_HTCD] [int] NOT NULL,
	[MKS_SCD] [bigint] NOT NULL,
	[MKS_TEKIYOYMD] [datetime] NOT NULL,
	[MKS_UPDATECNT] [int] NOT NULL,
	[MKS_STR] [datetime] NULL,
	[MKS_END] [datetime] NULL,
	[MKS_DELFG] [tinyint] NOT NULL,
	[MKS_INYMD] [datetime] NOT NULL,
	[MKS_INTANTO] [varchar](100) NOT NULL,
	[MKS_KOSINYMD] [datetime] NOT NULL,
	[MKS_KOSINTANTO] [varchar](100) NOT NULL,
 CONSTRAINT [PK_MIKEISAI_SCD_MST_old] PRIMARY KEY CLUSTERED 
(
	[MKS_KCD] ASC,
	[MKS_HTCD] ASC,
	[MKS_SCD] ASC,
	[MKS_TEKIYOYMD] ASC,
	[MKS_UPDATECNT] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
