<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
  xmlns:my="http://localhost/" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  exclude-result-prefixes="my xs">
  
  <xsl:param name="debug" as="xs:boolean" select="true()"/>
  
  <xsl:mode name="list-level" on-no-match="shallow-copy"/>
  
  
  <xsl:template match="/">
    <xsl:if test="$debug">
      <xsl:result-document href="debug1_atomic-items.xml">
        <xsl:apply-templates mode="list-level"/>
      </xsl:result-document>
    </xsl:if>
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="*[ol[@data-meta = 'listlevel=start']]" mode="list-level"
    priority="2">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="my:atomic-items(.)" mode="list-level"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[ancestor::li]" mode="list-level">
    <xsl:copy>
      <xsl:attribute name="list-level" select="count(ancestor::li)"/>
      <xsl:if test="parent::li[not(@data-meta='listitem=empty')]/parent::ol/@data-meta = 'listlevel=start'
                    and . is (parent::li/parent::ol/li/*)[1]">
        <xsl:attribute name="start" select="'true'"/>
      </xsl:if>
      <xsl:if test="parent::li/parent::ol[not(@data-meta)]
                    and . is (ancestor::ol[@data-meta][1]//*[empty(self::li | self::ol)])[1]">
        <xsl:attribute name="start-level" 
          select="count(ancestor::ol) - count(ancestor::ol[not(@data-meta)]) + 1"/>
      </xsl:if>
      <xsl:copy-of select="@* | node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[@data-meta='collect' 
                         or 
                         parent::li/@data-meta = 'listitem=continue'
                         or
                         (exists(parent::li) and not(. is parent::li/*[1]))]" 
                mode="list-level" priority="2">
    <xsl:copy-of select="."/>
  </xsl:template>
  
  <xsl:template match="*" mode="list-level">
    <xsl:copy>
      <xsl:attribute name="list-level" select="0"/>
      <xsl:copy-of select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[descendant::ol[@data-meta = 'listlevel=start']]" mode="list-level">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>