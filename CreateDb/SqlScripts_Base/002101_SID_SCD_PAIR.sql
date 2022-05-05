USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SID_SCD_PAIR]') AND type in (N'U'))
DROP TABLE [dbo].[SID_SCD_PAIR]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[SID_SCD_PAIR](
	[SSP_SID] [varchar](20) NOT NULL,
	[SSP_SCD] [bigint] NOT NULL,
	[SSP_INYMD] [datetime] NOT NULL,
 CONSTRAINT [PK_SID_SCD_PAIR] PRIMARY KEY CLUSTERED 
(
	[SSP_SID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [nci_SID_SCD_PAIR_SSP_SCD] ON [dbo].[SID_SCD_PAIR]
(
	[SSP_SCD] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
