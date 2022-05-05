USE [#{-BASE_DB-}#]
GO

DROP INDEX IF EXISTS [nci_SHOHIN_MST_now_SSHM_KOSINYMD_1] ON [dbo].[SHOHIN_MST_now]
GO

CREATE NONCLUSTERED INDEX [nci_SHOHIN_MST_now_SSHM_KOSINYMD_1] ON [dbo].[SHOHIN_MST_now]
(
	[SSHM_KOSINYMD] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
