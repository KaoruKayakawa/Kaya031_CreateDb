USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ft_TENPO_SETNO_MST]') AND type in (N'IF'))
DROP FUNCTION [dbo].[ft_TENPO_SETNO_MST]
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
CREATE FUNCTION [dbo].[ft_TENPO_SETNO_MST]
(	
	@date_base datetime
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT a.*
	FROM TENPO_SETNO_MST_now a
	INNER JOIN (
		SELECT TSM_KCD_1, TSM_TENSETNO, TSM_KCD_2, TSM_TENCD, MAX(TSM_TEKIYOYMD) AS TSM_TEKIYOYMD
		FROM TENPO_SETNO_MST_now
		WHERE TSM_TEKIYOYMD <= ISNULL(CAST(@date_base AS date), CAST(GETDATE() AS date))
			AND TSM_DELFG <> 1
		GROUP BY TSM_KCD_1, TSM_TENSETNO, TSM_KCD_2, TSM_TENCD) b
	ON a.TSM_KCD_1 = b.TSM_KCD_1
		AND a.TSM_TENSETNO = b.TSM_TENSETNO
		AND a.TSM_KCD_2 = b.TSM_KCD_2
		AND a.TSM_TENCD = b.TSM_TENCD
		AND a.TSM_TEKIYOYMD = b.TSM_TEKIYOYMD
	WHERE a.TSM_DELFG = 0
)
GO
