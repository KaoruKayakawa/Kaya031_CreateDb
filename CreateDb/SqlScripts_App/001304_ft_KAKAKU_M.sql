USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ft_KAKAKU_M]') AND type in (N'IF'))
DROP FUNCTION [dbo].[ft_KAKAKU_M]
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
CREATE FUNCTION [dbo].[ft_KAKAKU_M]
(
	@date_base datetime
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT a.*
	FROM KAKAKU_M_now a
	INNER JOIN (
		SELECT KAK_HTCD, KAK_SCD, KAK_KIKAKUCD, MAX(KAK_TEKIYOYMD) AS KAK_TEKIYOYMD
		FROM KAKAKU_M_now
		WHERE KAK_TEKIYOYMD <= ISNULL(CAST(@date_base AS date), CAST(GETDATE() AS date))
			AND KAK_DELFG <> 1
		GROUP BY KAK_HTCD, KAK_SCD, KAK_KIKAKUCD) b
	ON a.KAK_HTCD = b.KAK_HTCD
		AND a.KAK_SCD = b.KAK_SCD
		AND a.KAK_KIKAKUCD = b.KAK_KIKAKUCD
		AND a.KAK_TEKIYOYMD = b.KAK_TEKIYOYMD
	WHERE a.KAK_DELFG = 0
)
GO
