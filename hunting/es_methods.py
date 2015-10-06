import syslog

def save_metadata(attributes,doctype,esindex,es):
    """ Saves metadata in ElasticSearch - future self, please delete me as soon as we prove this"""
    fid=es.count({'query':{"match_all":{}}},index=esindex)['count']+1
    #syslog.syslog("["+str(fid)+"] i should save the following"+str(attributes))
    es.index(esindex, doctype, attributes, id=fid)


def simple_save_metadata(attributes,doctype,esindex,es):
    """ Simple method to save metadata in ElasticSearch"""
    # checking to see if the data is already here - for the moment only loooking at sha1 and md5 if they are here
    potential_keys=['md5','sha1','Name','hostname','fromAddress','toAddress'] 
    qsa=[]    
    for key, value in attributes.iteritems():
        if key in potential_keys:
            qsa.append(key+'='+value)
    es_res=es.search(' AND '.join(qsa), index=esindex, doc_type=doctype)
    if es_res['hits']['total'] > 0:
      #print '[*] already have ', attributes['sha1']
      metaid=es_res['hits']['hits'][0]['_id']
    else:
      metaid=es.count('*',index=esindex)['count']+1
      #print 'adding new item ', attributes['sha1']
    #syslog.syslog("["+str(fid)+"] i should save the following"+str(attributes))
    es.index(esindex, doctype, attributes, id=metaid)
    es.refresh(esindex)
