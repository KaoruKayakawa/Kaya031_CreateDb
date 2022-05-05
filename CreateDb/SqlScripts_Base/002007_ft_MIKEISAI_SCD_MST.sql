USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ft_MIKEISAI_SCD_MST]') AND type in (N'IF'))
DROP FUNCTION [dbo].[ft_MIKEISAI_SCD_MST]
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
CREATE FUNCTION [dbo].[ft_MIKEISAI_SCD_MST]
(
	@date_base datetime
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT a.*
	FROM MIKEISAI_SCD_MST_now a
	INNER JOIN (
		SELECT MKS_KCD, MKS_HTCD, MKS_SCD, MAX(MKS_TEKIYOYMD) AS MKS_TEKIYOYMD
		FROM MIKEISAI_SCD_MST_now
		WHERE MKS_TEKIYOYMD <= ISNULL(CAST(@date_base AS date), CAST(GETDATE() AS date))
			AND MKS_DELFG <> 1
		GROUP BY MKS_KCD, MKS_HTCD, MKS_SCD) b
	ON a.MKS_KCD = b.MKS_KCD
		AND a.MKS_HTCD = b.MKS_HTCD
		AND a.MKS_SCD = b.MKS_SCD
		AND a.MKS_TEKIYOYMD = b.MKS_TEKIYOYMD
	WHERE a.MKS_DELFG = 0
)
GO
