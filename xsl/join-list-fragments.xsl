<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
  xmlns:my="http://localhost/" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  exclude-result-prefixes="my xs">
  
  <xsl:mode on-no-match="shallow-copy"/>
  <xsl:output indent="yes"/>

  <xsl:include href="debug.xsl"/>
  
  <xsl:template match="*[ol[@data-meta = 'listlevel=start']]" mode="#default">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="my:atomic-items(.)" 
        group-starting-with="*[parent::li[not(@data-meta='listitem=empty')]
                                  /parent::ol/@data-meta = ('listlevel=start')
                               and . is (parent::li/parent::ol/li/*)[1]]">
        <xsl:for-each-group select="current-group()" group-adjacent="(my:list-level(.), -1)[1] = 0">
          <!-- Exclude the uninteresting paras before, in between, and after lists.
          For interesting elements, my:list-level() is greater than 0 or empty (for the collect
          elements, but also for continuing list item content) -->
          <xsl:choose>
            <xsl:when test="current-grouping-key()">
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="collect"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each-group>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="my:atomic-items" as="node()*">
    <xsl:param name="context" as="element()"/>
    <xsl:sequence select="  innermost($context/descendant::li/*[empty(ancestor::ol[@data-meta = 'listlevel=end'])])
                          | outermost($context/descendant::*[empty(ancestor-or-self::ol)])"/>
  </xsl:function>
  
  <xsl:function name="my:list-level" as="xs:integer?">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:choose>
      <xsl:when test="$elt[@data-meta='collect' 
                           or 
                           parent::li/@data-meta = 'listitem=continue'
                           or
                           (exists(parent::li) and not(. is parent::li/*[1]))]"/>
      <xsl:otherwise>
        <xsl:sequence select="count($elt[. is parent::li/*[1]]/ancestor::li)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:template name="collect">
    <xsl:param name="nodes" as="node()*" select="current-group()"/>
    <xsl:param name="depth" as="xs:integer" select="1"/>
    <xsl:copy select="../..">
      <!-- ol -->
      <xsl:copy-of select="@*"/>
      <xsl:for-each-group select="current-group()" group-starting-with="*[my:list-level(.) = $depth]">
        <xsl:copy select="..">
          <!-- li -->
          <xsl:copy-of select="@*"/>
          <xsl:choose>
            <xsl:when test="exists(current-group()[my:list-level(.) gt $depth])">
              <xsl:for-each-group select="current-group()" group-adjacent="not(my:list-level(.) = $depth)">
                <xsl:choose>
                  <xsl:when test="current-grouping-key()">
                    <!-- If it were not for <ol id="ol1.2"> in E7, the following grouping would be unnecessary.
                    It corresponds to start-level="2" in the debugging output. -->
                    <xsl:for-each-group select="current-group()" 
                      group-starting-with="*[parent::li/parent::ol[not(@data-meta)]
                                             and . is (ancestor::ol[@data-meta][1]//*[empty(self::li | self::ol)])[1]]">
                      <xsl:call-template name="collect">
                        <xsl:with-param name="depth" select="$depth + 1"/>
                      </xsl:call-template>  
                    </xsl:for-each-group>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:apply-templates select="current-group()" mode="#current"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each-group>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="current-group()" mode="#current"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:copy>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="li[@data-meta = 'listitem=empty']/*" mode="#default"/>
  
</xsl:stylesheet>