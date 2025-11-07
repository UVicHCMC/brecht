<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema" 
                exclude-result-prefixes="#all" 
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                version="3.0">
  
  <xsl:output method="xml" indent="yes" encoding="UTF-8" omit-xml-declaration="no"/>
  
  <!-- Get current document filename and page name -->
  <xsl:variable name="currentFile" select="tokenize(base-uri(/), '/')[last()]"/>
  <xsl:variable name="currentPage" select="replace($currentFile, '\.xml$', '.html')"/>
  
  <!-- Determine language from path (for bilingual builds) -->
  <xsl:variable name="pathParts" select="tokenize(base-uri(/), '/')"/>
  <xsl:variable name="langFromPath" select="
    if ($pathParts[last() - 1] = ('en', 'fr', 'de', 'es', 'it')) then
      $pathParts[last() - 1]
    else ''
                  "/>
  
  <!-- Load the appropriate template -->
  <xsl:variable name="templatePath" select="
    if ($langFromPath != '') then
      concat('../templates/', $langFromPath, '/contentPage.xml')
    else
      '../templates/contentPage.xml'
                  "/>
  
  <xsl:variable name="template" select="doc($templatePath)"/>
  
  <!-- Store the content document root for later use -->
  <xsl:variable name="contentRoot" select="/"/>
  
  <!-- Image dimensions handling -->
  <xsl:variable name="txtDimensions" select="unparsed-text('../utilities/imageDimensions.txt')"/>
  
  <xsl:variable name="mapImgPathsToElements" as="map(xs:string, element(Q{http://www.w3.org/1999/xhtml}img))">
    <xsl:map>
      <xsl:for-each select="distinct-values(tokenize($txtDimensions, '&#x0A;'))">
        <xsl:variable name="bits" as="xs:string*" select="tokenize(., '\s+')"/>
        <xsl:variable name="wh" as="xs:string*" select="if (count($bits) gt 1) then tokenize($bits[2], 'x') else ()"/>
        <xsl:if test="count($bits) = 2 and count($wh) = 2">
          <xsl:map-entry key="$bits[1]">
            <img xmlns="http://www.w3.org/1999/xhtml" src="{$bits[1]}" width="{$wh[1]}" height="{$wh[2]}"/>
          </xsl:map-entry>
        </xsl:if>
      </xsl:for-each>
    </xsl:map>
  </xsl:variable>
  
  <!-- Main template: Process the template document, not the content -->
  <xsl:template match="/">
    <xsl:apply-templates select="$template/*"/>
  </xsl:template>
  
  <!-- Identity template for template elements -->
  <xsl:template match="xhtml:* | @*" priority="1">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Replace <?docContent?> with actual content -->
  <xsl:template match="processing-instruction('docContent')" priority="5">
    <xsl:apply-templates select="$contentRoot/xhtml:body/*" mode="content"/>
  </xsl:template>
  
  <!-- Replace {{currentPage}} placeholders in href attributes -->
  <xsl:template match="@href[contains(., '{{currentPage}}')]" priority="3">
    <xsl:attribute name="href" select="replace(., '\{\{currentPage\}\}', $currentPage)"/>
  </xsl:template>
  
  <!-- Process content in content mode (identity transform with image handling) -->
  <xsl:template match="xhtml:* | @*" mode="content" priority="1">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="content"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Replace img tags with dimensioned versions (for template images) -->
  <xsl:template match="xhtml:img[starts-with(@src, 'images/') or starts-with(@src, '/images/')]" priority="2">
    <xsl:call-template name="add-image-dimensions">
      <xsl:with-param name="img" select="."/>
    </xsl:call-template>
  </xsl:template>
  
  <!-- Replace img tags with dimensioned versions (for content images) -->
  <xsl:template match="xhtml:img[starts-with(@src, 'images/') or starts-with(@src, '/images/')]" mode="content" priority="2">
    <xsl:call-template name="add-image-dimensions">
      <xsl:with-param name="img" select="."/>
    </xsl:call-template>
  </xsl:template>
  
  <!-- Named template to add image dimensions -->
  <xsl:template name="add-image-dimensions">
    <xsl:param name="img" as="element(xhtml:img)"/>
    
    <!-- Normalize the src path (remove leading slash if present) -->
    <xsl:variable name="normalizedSrc" select="replace($img/@src, '^/', '')"/>
    <xsl:variable name="imgTag" select="map:get($mapImgPathsToElements, $normalizedSrc)" as="element(xhtml:img)*"/>
    
    <xsl:choose>
      <xsl:when test="count($imgTag) > 0">
        <xsl:for-each select="$imgTag">
          <xsl:copy>
            <xsl:copy-of select="@width"/>
            <xsl:copy-of select="@height"/>
            <xsl:choose>
              <xsl:when test="$img/@class">
                <xsl:attribute name="class" select="concat($img/@class, ' ', ./@class)"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="@class"/>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:copy-of select="$img/@*[not(local-name() = 'width' or local-name() = 'height' or local-name() = 'class')]"/>
          </xsl:copy>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>Warning: No dimensions found for <xsl:value-of select="$img/@src"/></xsl:message>
        <xsl:copy>
          <xsl:apply-templates select="$img/@* | $img/node()" mode="#current"/>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>