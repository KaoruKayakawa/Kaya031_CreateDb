USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ft_KAKAKU_MST]') AND type in (N'IF'))
DROP FUNCTION [dbo].[ft_KAKAKU_MST]
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
CREATE FUNCTION [dbo].[ft_KAKAKU_MST]
(	
	@date_base datetime
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT a.*
	FROM KAKAKU_MST_now a
	INNER JOIN (
		SELECT SKAK_KCD, SKAK_HTCD, SKAK_SCD, SKAK_KIKAKUCD, MAX(SKAK_TEKIYOYMD) AS SKAK_TEKIYOYMD
		FROM KAKAKU_MST_now
		WHERE SKAK_TEKIYOYMD <= ISNULL(CAST(@date_base AS date), CAST(GETDATE() AS date))
			AND SKAK_DELFG <> 1
		GROUP BY SKAK_KCD, SKAK_HTCD, SKAK_SCD, SKAK_KIKAKUCD) b
	ON a.SKAK_KCD = b.SKAK_KCD
		AND a.SKAK_HTCD = b.SKAK_HTCD
		AND a.SKAK_SCD = b.SKAK_SCD
		AND a.SKAK_KIKAKUCD = b.SKAK_KIKAKUCD
		AND a.SKAK_TEKIYOYMD = b.SKAK_TEKIYOYMD
	WHERE a.SKAK_DELFG = 0
)
GO
