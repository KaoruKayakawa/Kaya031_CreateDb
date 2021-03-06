USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MIXMATCH_M]') AND type in (N'U'))
DROP TABLE [dbo].[MIXMATCH_M]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MIXMATCH_M](
	[MIM_HTCD] [int] NOT NULL,
	[MIM_MMNO] [int] NOT NULL,
	[MIM_SCD] [bigint] NOT NULL,
	[MIM_INYMD] [datetime] NOT NULL,
	[MIM_KOSINYMD] [datetime] NOT NULL,
	[MIM_KOSINTIME] [datetime] NOT NULL,
 CONSTRAINT [PK_MIXMATCH_M] PRIMARY KEY CLUSTERED 
(
	[MIM_HTCD] ASC,
	[MIM_MMNO] ASC,
	[MIM_SCD] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
