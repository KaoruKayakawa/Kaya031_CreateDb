USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ft_SHOHIN_SHOSAI_M]') AND type in (N'IF'))
DROP FUNCTION [dbo].[ft_SHOHIN_SHOSAI_M]
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
CREATE FUNCTION [dbo].[ft_SHOHIN_SHOSAI_M]
(
	@date_base datetime
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT a.*
	FROM SHOHIN_SHOSAI_M_now a
	INNER JOIN (
		SELECT SSM_HTCD, SSM_SCD, MAX(SSM_TEKIYOYMD) AS SSM_TEKIYOYMD
		FROM SHOHIN_SHOSAI_M_now
		WHERE SSM_TEKIYOYMD <= ISNULL(CAST(@date_base AS date), CAST(GETDATE() AS date))
			AND SSM_DELFG <> 1
		GROUP BY SSM_HTCD, SSM_SCD) b
	ON a.SSM_HTCD = b.SSM_HTCD
		AND a.SSM_SCD = b.SSM_SCD
		AND a.SSM_TEKIYOYMD = b.SSM_TEKIYOYMD
	WHERE a.SSM_DELFG = 0
)
GO
